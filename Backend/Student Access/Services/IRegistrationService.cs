using EventPassApi.Dtos.Registrations;

namespace EventPassApi.Services;

public interface IRegistrationService
{
    Task<RegistrationResponseDto> RegisterForEventAsync(int userId, int eventId);
    Task<RegistrationResponseDto?> GetMyPassAsync(int userId, int? eventId = null);
    Task<List<RegistrationResponseDto>> GetMyRegistrationsAsync(int userId);
}

public class RegistrationException : Exception
{
    public int StatusCode { get; }
    public RegistrationException(string message, int statusCode) : base(message)
    {
        StatusCode = statusCode;
    }
}