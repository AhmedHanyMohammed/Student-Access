using EventPassApi.Dtos.Events;
using EventPassApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EventPassApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EventsController : ControllerBase
{
    private readonly IEventService _eventService;

    public EventsController(IEventService eventService)
    {
        _eventService = eventService;
    }

    /// <summary>
    /// Gets all active events available for registration, optionally filtered by category.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(List<EventDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetActiveEvents([FromQuery] int? categoryId = null)
    {
        var events = await _eventService.GetActiveEventsAsync(categoryId);
        return Ok(events);
    }

    /// <summary>
    /// Gets event details by ID.
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(EventDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id)
    {
        var ev = await _eventService.GetByIdAsync(id);
        if (ev == null)
        {
            return NotFound(new { message = $"Event with ID {id} not found." });
        }
        return Ok(ev);
    }

    /// <summary>
    /// Creates a new event (SuperAdmin or Category Admin).
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "SuperAdmin,Admin")]
    [ProducesResponseType(typeof(EventDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(object), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Create([FromBody] CreateEventDto request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        // If user is a Category Admin, enforce their assigned category
        if (!User.IsInRole("SuperAdmin"))
        {
            var adminCategoryClaim = User.FindFirst("CategoryId")?.Value;
            if (int.TryParse(adminCategoryClaim, out var adminCatId))
            {
                request.CategoryId = adminCatId;
            }
        }

        var created = await _eventService.CreateAsync(request);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    /// <summary>
    /// Updates an existing event details (SuperAdmin or Category Admin).
    /// </summary>
    [HttpPut("{id:int}")]
    [Authorize(Roles = "SuperAdmin,Admin")]
    [ProducesResponseType(typeof(EventDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(object), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateEventDto request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        // Category verification for Category Admins
        if (!User.IsInRole("SuperAdmin"))
        {
            var existing = await _eventService.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { message = $"Event with ID {id} not found." });
            }

            var adminCategoryClaim = User.FindFirst("CategoryId")?.Value;
            if (int.TryParse(adminCategoryClaim, out var adminCatId) && existing.CategoryId != adminCatId)
            {
                return Forbid();
            }

            request.CategoryId = adminCatId;
        }

        var updated = await _eventService.UpdateAsync(id, request);
        if (updated == null)
        {
            return NotFound(new { message = $"Event with ID {id} not found." });
        }
        return Ok(updated);
    }

    /// <summary>
    /// Deletes an event (SuperAdmin or Category Admin).
    /// </summary>
    [HttpDelete("{id:int}")]
    [Authorize(Roles = "SuperAdmin,Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            var existing = await _eventService.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { message = $"Event with ID {id} not found." });
            }

            var adminCategoryClaim = User.FindFirst("CategoryId")?.Value;
            if (int.TryParse(adminCategoryClaim, out var adminCatId) && existing.CategoryId != adminCatId)
            {
                return Forbid();
            }
        }

        var deleted = await _eventService.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = $"Event with ID {id} not found." });
        }
        return Ok(new { message = $"Event {id} deleted successfully." });
    }

    /// <summary>
    /// Updates active/inactive status of an event (SuperAdmin or Category Admin).
    /// </summary>
    [HttpPatch("{id:int}/status")]
    [Authorize(Roles = "SuperAdmin,Admin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] bool isActive)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            var existing = await _eventService.GetByIdAsync(id);
            if (existing == null)
            {
                return NotFound(new { message = $"Event with ID {id} not found." });
            }

            var adminCategoryClaim = User.FindFirst("CategoryId")?.Value;
            if (int.TryParse(adminCategoryClaim, out var adminCatId) && existing.CategoryId != adminCatId)
            {
                return Forbid();
            }
        }

        var updated = await _eventService.SetActiveStatusAsync(id, isActive);
        if (!updated)
        {
            return NotFound(new { message = $"Event with ID {id} not found." });
        }
        return Ok(new { message = $"Event {id} status updated.", isActive });
    }

    /// <summary>
    /// Gets all registered users for a specific event (SuperAdmin or Category Admin).
    /// </summary>
    [HttpGet("{eventId:int}/registrations")]
    [Authorize(Roles = "SuperAdmin,Admin")]
    [ProducesResponseType(typeof(List<EventPassApi.Dtos.Registrations.RegistrationResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetEventRegistrations(int eventId, [FromServices] IRegistrationService registrationService)
    {
        if (!User.IsInRole("SuperAdmin"))
        {
            var existing = await _eventService.GetByIdAsync(eventId);
            if (existing == null)
            {
                return NotFound(new { message = $"Event with ID {eventId} not found." });
            }

            var adminCategoryClaim = User.FindFirst("CategoryId")?.Value;
            if (int.TryParse(adminCategoryClaim, out var adminCatId) && existing.CategoryId != adminCatId)
            {
                return Forbid();
            }
        }

        var registrations = await registrationService.GetEventRegistrationsAsync(eventId);
        return Ok(registrations);
    }
}
