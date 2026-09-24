using System.ComponentModel.DataAnnotations;

namespace EventPassApi.Models;

public class User
{
    public int Id { get; set; }

    [Required, MaxLength(150)]
    public string FullName { get; set; } = string.Empty;

    [MaxLength(30)]
    public string? Phone { get; set; }

    [Required, MaxLength(200)]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string PasswordHash { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Required, MaxLength(20)]
    public string Role { get; set; } = "Student";

    // Navigation
    public ICollection<Registration> Registrations { get; set; } = new List<Registration>();
}