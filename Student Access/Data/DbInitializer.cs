using EventPassApi.Models;
using Microsoft.EntityFrameworkCore;

namespace EventPassApi.Data;

public static class DbInitializer
{
    public static async Task InitializeAsync(AppDbContext context)
    {
        // Ensure database and tables are created
        await context.Database.EnsureCreatedAsync();

        // Seed initial event if none exists
        if (!await context.Events.AnyAsync())
        {
            context.Events.AddRange(
                new Event
                {
                    Title = "Student Tech Fest 2026",
                    Description = "Annual flagship conference celebrating student innovation, coding projects, and keynote speakers from top tech companies.",
                    Location = "Main Campus Hall & Innovation Center, Auditorium A",
                    EventDate = DateTime.UtcNow.AddDays(7),
                    IsActive = true
                },
                new Event
                {
                    Title = "AI & Mobile Development Workshop",
                    Description = "Hands-on workshop building cross-platform Flutter apps powered by modern cloud APIs and AI agents.",
                    Location = "Computer Science Building, Lab 302",
                    EventDate = DateTime.UtcNow.AddDays(14),
                    IsActive = true
                },
                new Event
                {
                    Title = "Spring Hackathon 2026",
                    Description = "48-hour continuous student hackathon with mentorship, food, prizes, and demo day.",
                    Location = "Student Activity Center - Arena",
                    EventDate = DateTime.UtcNow.AddDays(30),
                    IsActive = true
                }
            );

            await context.SaveChangesAsync();
        }
    }
}
