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

    public async Task<List<EventDto>> GetActiveEventsAsync(int? categoryId = null)
    {
        var query = _db.Events
            .Include(e => e.Category)
            .Where(e => e.IsActive);

        if (categoryId.HasValue && categoryId.Value > 0)
        {
            query = query.Where(e => e.CategoryId == categoryId.Value);
        }

        return await query
            .OrderBy(e => e.EventDate)
            .Select(e => ToDto(e))
            .ToListAsync();
    }

    public async Task<EventDto?> GetByIdAsync(int id)
    {
        var ev = await _db.Events
            .Include(e => e.Category)
            .FirstOrDefaultAsync(e => e.Id == id);

        return ev == null ? null : ToDto(ev);
    }

    public async Task<EventDto> CreateAsync(CreateEventDto request)
    {
        var categoryId = request.CategoryId.GetValueOrDefault(1);
        if (categoryId <= 0 || !await _db.Categories.AnyAsync(c => c.Id == categoryId))
        {
            var defaultCat = await _db.Categories.OrderBy(c => c.Id).FirstOrDefaultAsync();
            categoryId = defaultCat?.Id ?? 1;
        }

        var ev = new Event
        {
            Title = request.Title.Trim(),
            Description = request.Description,
            EventDate = DateTime.SpecifyKind(request.EventDate, DateTimeKind.Utc),
            Location = request.Location.Trim(),
            CategoryId = categoryId,
            IsActive = true
        };

        _db.Events.Add(ev);
        await _db.SaveChangesAsync();

        // Reload category for DTO
        await _db.Entry(ev).Reference(e => e.Category).LoadAsync();

        return ToDto(ev);
    }

    public async Task<EventDto?> UpdateAsync(int id, CreateEventDto request)
    {
        var ev = await _db.Events
            .Include(e => e.Category)
            .FirstOrDefaultAsync(e => e.Id == id);

        if (ev == null)
        {
            return null;
        }

        ev.Title = request.Title.Trim();
        ev.Description = request.Description;
        ev.EventDate = DateTime.SpecifyKind(request.EventDate, DateTimeKind.Utc);
        ev.Location = request.Location.Trim();

        if (request.CategoryId.HasValue && request.CategoryId.Value > 0)
        {
            if (await _db.Categories.AnyAsync(c => c.Id == request.CategoryId.Value))
            {
                ev.CategoryId = request.CategoryId.Value;
            }
        }

        await _db.SaveChangesAsync();
        await _db.Entry(ev).Reference(e => e.Category).LoadAsync();

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
        IsActive = e.IsActive,
        CategoryId = e.CategoryId,
        CategoryName = e.Category?.Name
    };
}