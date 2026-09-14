using EventPassApi.Data;
using EventPassApi.Dtos.Scans;
using EventPassApi.Models;
using Microsoft.EntityFrameworkCore;

namespace EventPassApi.Services;

public class ScanService : IScanService
{
    private readonly AppDbContext _db;

    public ScanService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<ScanResultDto> ProcessScanAsync(ScanRequestDto request)
    {
        var registration = await _db.Registrations
            .Include(r => r.User)
            .Include(r => r.Event)
            .FirstOrDefaultAsync(r => r.QrToken == request.QrToken);

        // State: invalid
        if (registration == null)
        {
            await LogScan(null, request.QrToken, ScanResult.Invalid, request.ScannedBy);

            return new ScanResultDto
            {
                Success = false,
                Status = "invalid",
                Result = ScanResult.Invalid.ToString(),
                Message = "This QR code is invalid or not recognized."
            };
        }

        // State: inactive
        if (!registration.Event.IsActive)
        {
            await LogScan(registration.Id, request.QrToken, ScanResult.Inactive, request.ScannedBy);
            return Fail(registration, "inactive", ScanResult.Inactive, "This event is currently inactive.");
        }

        // State: cancelled
        if (registration.Status == RegistrationStatus.Cancelled)
        {
            await LogScan(registration.Id, request.QrToken, ScanResult.Cancelled, request.ScannedBy);
            return Fail(registration, "cancelled", ScanResult.Cancelled, "This registration was cancelled.");
        }

        // State: already checked in
        if (registration.Status == RegistrationStatus.CheckedIn)
        {
            await LogScan(registration.Id, request.QrToken, ScanResult.AlreadyCheckedIn, request.ScannedBy);
            return Fail(
                registration,
                "already checked in",
                ScanResult.AlreadyCheckedIn,
                $"Already checked in at {registration.CheckedInAt:yyyy-MM-dd HH:mm:ss UTC}.",
                registration.CheckedInAt);
        }

        // State: valid (First time check-in)
        registration.Status = RegistrationStatus.CheckedIn;
        registration.CheckedInAt = DateTime.UtcNow;

        await LogScan(registration.Id, request.QrToken, ScanResult.Valid, request.ScannedBy);
        await _db.SaveChangesAsync();

        return new ScanResultDto
        {
            Success = true,
            Status = "valid",
            Result = ScanResult.Valid.ToString(),
            Message = "Check-in successful. Pass is valid.",
            AttendeeName = registration.User.FullName,
            AttendeeEmail = registration.User.Email,
            EventTitle = registration.Event.Title,
            CheckedInAt = registration.CheckedInAt
        };
    }

    private static ScanResultDto Fail(
        Registration registration,
        string status,
        ScanResult result,
        string message,
        DateTime? checkedInAt = null) => new()
        {
            Success = false,
            Status = status,
            Result = result.ToString(),
            Message = message,
            AttendeeName = registration.User.FullName,
            AttendeeEmail = registration.User.Email,
            EventTitle = registration.Event.Title,
            CheckedInAt = checkedInAt
        };

    private async Task LogScan(int? registrationId, string? token, ScanResult result, string? scannedBy)
    {
        _db.ScanLogs.Add(new ScanLog
        {
            RegistrationId = registrationId,
            ScannedToken = token,
            ScanResult = result,
            ScannedAt = DateTime.UtcNow,
            ScannedBy = scannedBy
        });
        await _db.SaveChangesAsync();
    }
}