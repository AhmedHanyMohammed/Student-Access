using EventPassApi.Dtos.Events;

namespace EventPassApi.Services;

public interface IEventService
{
    Task<List<EventDto>> GetActiveEventsAsync();
    Task<EventDto?> GetByIdAsync(int id);
    Task<EventDto> CreateAsync(CreateEventDto request);
    Task<EventDto?> UpdateAsync(int id, CreateEventDto request);
    Task<bool> DeleteAsync(int id);
    Task<bool> SetActiveStatusAsync(int id, bool isActive);
}