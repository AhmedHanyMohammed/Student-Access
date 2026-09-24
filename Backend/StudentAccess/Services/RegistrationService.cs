using System.Security.Cryptography;
using EventPassApi.Data;
using EventPassApi.Dtos.Registrations;
using EventPassApi.Models;
using Microsoft.EntityFrameworkCore;

namespace EventPassApi.Services;

public class RegistrationService : IRegistrationService
{
    private readonly AppDbContext _db;

    public RegistrationService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<RegistrationResponseDto> RegisterForEventAsync(int userId, int eventId)
    {
        var ev = await _db.Events.FindAsync(eventId);
        if (ev == null || !ev.IsActive)
        {
            throw new RegistrationException("Event not found or no longer open for registration.", StatusCodes.Status404NotFound);
        }

        var user = await _db.Users.FindAsync(userId);
        if (user == null)
        {
            throw new RegistrationException("User not found.", StatusCodes.Status404NotFound);
        }

        if (string.Equals(user.Role, "Admin", StringComparison.OrdinalIgnoreCase))
        {
            throw new RegistrationException("Admins cannot register for events as attendees.", StatusCodes.Status403Forbidden);
        }

        var alreadyRegistered = await _db.Registrations
            .AnyAsync(r => r.UserId == userId && r.EventId == eventId);
        if (alreadyRegistered)
        {
            throw new RegistrationException("You are already registered for this event.", StatusCodes.Status409Conflict);
        }

        var registration = new Registration
        {
            UserId = userId,
            EventId = eventId,
            QrToken = GenerateUniqueToken(),
            Status = RegistrationStatus.Registered,
            RegisteredAt = DateTime.UtcNow
        };

        _db.Registrations.Add(registration);
        await _db.SaveChangesAsync();

        return new RegistrationResponseDto
        {
            Id = registration.Id,
            EventId = ev.Id,
            EventTitle = ev.Title,
            EventDescription = ev.Description,
            EventLocation = ev.Location,
            EventDate = ev.EventDate,
            QrToken = registration.QrToken,
            Status = registration.Status.ToString(),
            AttendeeName = user.FullName,
            AttendeeEmail = user.Email,
            RegisteredAt = registration.RegisteredAt,
            CheckedInAt = registration.CheckedInAt
        };
    }

    public async Task<RegistrationResponseDto?> GetMyPassAsync(int userId, int? eventId = null)
    {
        var query = _db.Registrations
            .Where(r => r.UserId == userId);

        if (eventId.HasValue)
        {
            query = query.Where(r => r.EventId == eventId.Value);
        }

        var reg = await query
            .Include(r => r.Event)
            .Include(r => r.User)
            .OrderByDescending(r => r.RegisteredAt)
            .FirstOrDefaultAsync();

        if (reg == null)
        {
            return null;
        }

        return MapToDto(reg);
    }

    public async Task<List<RegistrationResponseDto>> GetMyRegistrationsAsync(int userId)
    {
        return await _db.Registrations
            .Where(r => r.UserId == userId)
            .Include(r => r.Event)
            .Include(r => r.User)
            .OrderByDescending(r => r.RegisteredAt)
            .Select(r => MapToDto(r))
            .ToListAsync();
    }

    public async Task<List<RegistrationResponseDto>> GetEventRegistrationsAsync(int eventId)
    {
        return await _db.Registrations
            .Where(r => r.EventId == eventId)
            .Include(r => r.Event)
            .Include(r => r.User)
            .OrderByDescending(r => r.RegisteredAt)
            .Select(r => MapToDto(r))
            .ToListAsync();
    }

    public async Task<bool> RemoveRegistrationAsync(int registrationId)
    {
        var reg = await _db.Registrations.FindAsync(registrationId);
        if (reg == null)
        {
            return false;
        }

        _db.Registrations.Remove(reg);
        await _db.SaveChangesAsync();
        return true;
    }

    private static RegistrationResponseDto MapToDto(Registration r) => new()
    {
        Id = r.Id,
        EventId = r.EventId,
        EventTitle = r.Event.Title,
        EventDescription = r.Event.Description,
        EventLocation = r.Event.Location,
        EventDate = r.Event.EventDate,
        QrToken = r.QrToken,
        Status = r.Status.ToString(),
        AttendeeName = r.User.FullName,
        AttendeeEmail = r.User.Email,
        RegisteredAt = r.RegisteredAt,
        CheckedInAt = r.CheckedInAt
    };

    /// <summary>
    /// Generates a cryptographically random, URL-safe token and
    /// guards against the astronomically unlikely event of a collision.
    /// </summary>
    private string GenerateUniqueToken()
    {
        string token;
        do
        {
            var bytes = RandomNumberGenerator.GetBytes(24);
            token = Convert.ToBase64String(bytes)
                .Replace("+", "-")
                .Replace("/", "_")
                .Replace("=", "");
        } while (_db.Registrations.Any(r => r.QrToken == token));

        return token;
    }
}