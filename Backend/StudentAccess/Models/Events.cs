using System.ComponentModel.DataAnnotations;

namespace EventPassApi.Models;

public class Event
{
    public int Id { get; set; }

    [Required, MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    [Required]
    public DateTime EventDate { get; set; }

    [Required, MaxLength(250)]
    public string Location { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    // Category association (defaults to 1 = General)
    public int CategoryId { get; set; } = 1;
    public Category? Category { get; set; }

    // Navigation
    public ICollection<Registration> Registrations { get; set; } = new List<Registration>();
}