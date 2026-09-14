namespace EventPassApi.Models;

public enum RegistrationStatus
{
    Registered = 0,
    CheckedIn = 1,
    Cancelled = 2
}

public class Registration
{
    public int Id { get; set; }

    public int UserId { get; set; }
    public User User { get; set; } = null!;

    public int EventId { get; set; }
    public Event Event { get; set; } = null!;

    /// <summary>
    /// Unique opaque token encoded into the QR code. Never reuse or
    /// guess this value — it is the sole credential checked at scan time.
    /// </summary>
    public string QrToken { get; set; } = string.Empty;

    public RegistrationStatus Status { get; set; } = RegistrationStatus.Registered;

    public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;

    public DateTime? CheckedInAt { get; set; }

    // Navigation
    public ICollection<ScanLog> ScanLogs { get; set; } = new List<ScanLog>();
}