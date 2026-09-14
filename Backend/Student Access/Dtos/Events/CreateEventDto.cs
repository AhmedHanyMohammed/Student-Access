using System.ComponentModel.DataAnnotations;

namespace EventPassApi.Dtos.Events;

public class CreateEventDto
{
    [Required, MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    [Required]
    public DateTime EventDate { get; set; }

    [Required, MaxLength(250)]
    public string Location { get; set; } = string.Empty;
}