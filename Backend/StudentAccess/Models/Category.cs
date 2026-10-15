using System.ComponentModel.DataAnnotations;

namespace EventPassApi.Models;

public class Category
{
    public int Id { get; set; }

    [Required, MaxLength(50)]
    public string Name { get; set; } = string.Empty;

    [Required, MaxLength(50)]
    public string Slug { get; set; } = string.Empty;

    [MaxLength(250)]
    public string? Description { get; set; }

    [MaxLength(10)]
    public string ColorHex { get; set; } = "#6C63FF";

    [MaxLength(30)]
    public string IconName { get; set; } = "event";

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public ICollection<Event> Events { get; set; } = new List<Event>();
    public ICollection<User> AssignedAdmins { get; set; } = new List<User>();
}
