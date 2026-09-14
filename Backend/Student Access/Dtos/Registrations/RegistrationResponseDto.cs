namespace EventPassApi.Dtos.Registrations;

public class RegistrationResponseDto
{
    public int Id { get; set; }
    public int EventId { get; set; }
    public string EventTitle { get; set; } = string.Empty;
    public string? EventDescription { get; set; }
    public string? EventLocation { get; set; }
    public DateTime? EventDate { get; set; }
    public string QrToken { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? AttendeeName { get; set; }
    public string? AttendeeEmail { get; set; }
    public DateTime RegisteredAt { get; set; }
    public DateTime? CheckedInAt { get; set; }
}