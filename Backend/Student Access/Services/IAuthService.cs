using EventPassApi.Dtos.Auth;

namespace EventPassApi.Services;

public interface IAuthService
{
    Task<AuthResponseDto> RegisterAsync(RegisterRequestDto request);
    Task<AuthResponseDto> LoginAsync(LoginRequestDto request);
}

/// <summary>
/// Thrown for expected auth failures (duplicate email, bad credentials)
/// so controllers can map them to the right HTTP status without
/// catching generic exceptions.
/// </summary>
public class AuthException : Exception
{
    public int StatusCode { get; }
    public AuthException(string message, int statusCode) : base(message)
    {
        StatusCode = statusCode;
    }
}