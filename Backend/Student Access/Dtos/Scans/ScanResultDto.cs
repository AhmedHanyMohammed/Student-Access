namespace EventPassApi.Dtos.Scans;

public class ScanResultDto
{
    public bool Success { get; set; }

    /// <summary>
    /// Scan state: "valid", "already checked in", "invalid", or "inactive"
    /// </summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>
    /// Enum code representation (e.g. "Valid", "AlreadyCheckedIn", "Invalid", "Inactive")
    /// </summary>
    public string Result { get; set; } = string.Empty;

    public string Message { get; set; } = string.Empty;

    // Populated when the token matched a real registration, even on failure,
    // so the scanner UI can show attendee details.
    public string? AttendeeName { get; set; }
    public string? AttendeeEmail { get; set; }
    public string? EventTitle { get; set; }
    public DateTime? CheckedInAt { get; set; }
}