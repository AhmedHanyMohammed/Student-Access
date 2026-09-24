using EventPassApi.Data;
using EventPassApi.Dtos.Events;
using EventPassApi.Models;
using Microsoft.EntityFrameworkCore;

namespace EventPassApi.Services;

public class EventService : IEventService
{
    private readonly AppDbContext _db;

    public EventService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<List<EventDto>> GetActiveEventsAsync()
    {
        return await _db.Events
            .Where(e => e.IsActive)
            .OrderBy(e => e.EventDate)
            .Select(e => ToDto(e))
            .ToListAsync();
    }

    public async Task<EventDto?> GetByIdAsync(int id)
    {
        var ev = await _db.Events.FindAsync(id);
        return ev == null ? null : ToDto(ev);
    }

    public async Task<EventDto> CreateAsync(CreateEventDto request)
    {
        var ev = new Event
        {
            Title = request.Title.Trim(),
            Description = request.Description,
            EventDate = request.EventDate,
            Location = request.Location.Trim(),
            IsActive = true
        };

        _db.Events.Add(ev);
        await _db.SaveChangesAsync();

        return ToDto(ev);
    }

    public async Task<EventDto?> UpdateAsync(int id, CreateEventDto request)
    {
        var ev = await _db.Events.FindAsync(id);
        if (ev == null)
        {
            return null;
        }

        ev.Title = request.Title.Trim();
        ev.Description = request.Description;
        ev.EventDate = request.EventDate;
        ev.Location = request.Location.Trim();

        await _db.SaveChangesAsync();
        return ToDto(ev);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var ev = await _db.Events.FindAsync(id);
        if (ev == null)
        {
            return false;
        }

        _db.Events.Remove(ev);
        await _db.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SetActiveStatusAsync(int id, bool isActive)
    {
        var ev = await _db.Events.FindAsync(id);
        if (ev == null)
        {
            return false;
        }

        ev.IsActive = isActive;
        await _db.SaveChangesAsync();
        return true;
    }

    private static EventDto ToDto(Event e) => new()
    {
        Id = e.Id,
        Title = e.Title,
        Description = e.Description,
        EventDate = e.EventDate,
        Location = e.Location,
        IsActive = e.IsActive
    };
}