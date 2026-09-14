namespace EventPassApi.Models;

public enum ScanResult
{
    Valid = 0,
    AlreadyCheckedIn = 1,
    Invalid = 2,
    Inactive = 3,
    Cancelled = 4
}

public class ScanLog
{
    public int Id { get; set; }

    public int? RegistrationId { get; set; }
    public Registration? Registration { get; set; }

    public string? ScannedToken { get; set; }

    public ScanResult ScanResult { get; set; }

    public DateTime ScannedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Identifier of the staff member / device / account that performed
    /// the scan (e.g. staff user id or gate device name).
    /// </summary>
    public string? ScannedBy { get; set; }
}