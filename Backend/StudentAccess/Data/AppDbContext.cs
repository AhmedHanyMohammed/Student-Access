using EventPassApi.Models;
using Microsoft.EntityFrameworkCore;

namespace EventPassApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<Registration> Registrations => Set<Registration>();
    public DbSet<ScanLog> ScanLogs => Set<ScanLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Users
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.Id);
            entity.HasIndex(u => u.Email).IsUnique();
            entity.Property(u => u.FullName).IsRequired().HasMaxLength(150);
            entity.Property(u => u.Email).IsRequired().HasMaxLength(200);
            entity.Property(u => u.PasswordHash).IsRequired();
            entity.Property(u => u.Phone).HasMaxLength(30);
            entity.Property(u => u.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
        });

        // Events
        modelBuilder.Entity<Event>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Location).IsRequired().HasMaxLength(250);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
        });

        // Registrations
        modelBuilder.Entity<Registration>(entity =>
        {
            entity.HasKey(r => r.Id);
            entity.HasIndex(r => r.QrToken).IsUnique();
            entity.HasIndex(r => new { r.UserId, r.EventId }).IsUnique();

            entity.HasOne(r => r.User)
                  .WithMany(u => u.Registrations)
                  .HasForeignKey(r => r.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(r => r.Event)
                  .WithMany(e => e.Registrations)
                  .HasForeignKey(r => r.EventId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.Property(r => r.Status)
                  .HasConversion<int>();
        });

        // ScanLogs
        modelBuilder.Entity<ScanLog>(entity =>
        {
            entity.HasKey(s => s.Id);
            entity.Property(s => s.ScannedToken).HasMaxLength(255);

            entity.HasOne(s => s.Registration)
                  .WithMany(r => r.ScanLogs)
                  .HasForeignKey(s => s.RegistrationId)
                  .IsRequired(false)
                  .OnDelete(DeleteBehavior.SetNull);

            entity.Property(s => s.ScanResult)
                  .HasConversion<int>();
        });
    }
}
