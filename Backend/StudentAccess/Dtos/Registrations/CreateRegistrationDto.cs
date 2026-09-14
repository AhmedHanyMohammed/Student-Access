using System.ComponentModel.DataAnnotations;

namespace EventPassApi.Dtos.Registrations;

public class CreateRegistrationDto
{
    [Required]
    public int EventId { get; set; }
}
