using System.Security.Claims;
using EventPassApi.Dtos.Registrations;
using EventPassApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EventPassApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class RegistrationsController : ControllerBase
{
    private readonly IRegistrationService _registrationService;

    public RegistrationsController(IRegistrationService registrationService)
    {
        _registrationService = registrationService;
    }

    /// <summary>
    /// Registers the currently authenticated student user for an event and returns their unique QR pass token.
    /// </summary>
    [HttpPost]
    [HttpPost("join")]
    [ProducesResponseType(typeof(RegistrationResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(object), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(object), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(object), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(object), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(object), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Register([FromBody] CreateRegistrationDto request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized(new { message = "User identity could not be verified from token." });
        }

        try
        {
            var result = await _registrationService.RegisterForEventAsync(userId.Value, request.EventId);
            return Ok(result);
        }
        catch (RegistrationException ex)
        {
            return StatusCode(ex.StatusCode, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Gets the current QR pass for the authenticated user (optionally filtered by eventId).
    /// </summary>
    [HttpGet("my-pass")]
    [ProducesResponseType(typeof(RegistrationResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(object), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(object), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetMyPass([FromQuery] int? eventId = null)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized(new { message = "User identity could not be verified from token." });
        }

        var pass = await _registrationService.GetMyPassAsync(userId.Value, eventId);
        if (pass == null)
        {
            return NotFound(new { message = "No active event pass found for this user." });
        }

        return Ok(pass);
    }

    /// <summary>
    /// Gets all registrations for the authenticated user.
    /// </summary>
    [HttpGet("my")]
    [HttpGet("my-list")]
    [ProducesResponseType(typeof(List<RegistrationResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(object), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyRegistrations()
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return Unauthorized(new { message = "User identity could not be verified from token." });
        }

        var list = await _registrationService.GetMyRegistrationsAsync(userId.Value);
        return Ok(list);
    }

    /// <summary>
    /// Removes/cancels a registration (Admin only).
    /// </summary>
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RemoveRegistration(int id)
    {
        var removed = await _registrationService.RemoveRegistrationAsync(id);
        if (!removed)
        {
            return NotFound(new { message = $"Registration with ID {id} not found." });
        }
        return Ok(new { message = $"Registration {id} removed successfully." });
    }

    private int? GetCurrentUserId()
    {
        var claimValue = User.FindFirstValue(ClaimTypes.NameIdentifier)
                      ?? User.FindFirstValue("sub")
                      ?? User.FindFirst("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier")?.Value;

        if (int.TryParse(claimValue, out var id))
        {
            return id;
        }

        return null;
    }
}
