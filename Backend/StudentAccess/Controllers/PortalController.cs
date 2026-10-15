using System.Security.Claims;
using EventPassApi.Data;
using EventPassApi.Models;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EventPassApi.Controllers;

[Route("[controller]")]
public class PortalController : Controller
{
    private readonly AppDbContext _db;

    public PortalController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public IActionResult Index()
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectToAction(nameof(Dashboard));
        }
        return RedirectToAction(nameof(Login));
    }

    // ----------------------------------------------------
    // AUTHENTICATION
    // ----------------------------------------------------

    [HttpGet("Login")]
    public IActionResult Login()
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectToAction(nameof(Dashboard));
        }
        return View();
    }

    [HttpPost("Login")]
    public async Task<IActionResult> Login([FromForm] string email, [FromForm] string password)
    {
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            ViewBag.Error = "Please provide both email and password.";
            return View();
        }

        var normalizedEmail = email.Trim().ToLowerInvariant();
        var user = await _db.Users
            .Include(u => u.AssignedCategory)
            .FirstOrDefaultAsync(u => u.Email == normalizedEmail);

        if (user == null || !BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
        {
            ViewBag.Error = "Invalid email or password.";
            return View();
        }

        if (user.Role != "SuperAdmin" && user.Role != "Admin")
        {
            ViewBag.Error = "Access denied. Only administrators can access this portal.";
            return View();
        }

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Email, user.Email),
            new(ClaimTypes.Name, user.FullName),
            new(ClaimTypes.Role, user.Role)
        };

        if (user.AssignedCategoryId.HasValue)
        {
            claims.Add(new Claim("CategoryId", user.AssignedCategoryId.Value.ToString()));
            if (!string.IsNullOrEmpty(user.AssignedCategory?.Name))
            {
                claims.Add(new Claim("CategoryName", user.AssignedCategory.Name));
            }
        }

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        var principal = new ClaimsPrincipal(identity);

        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);

        return RedirectToAction(nameof(Dashboard));
    }

    [HttpGet("Logout")]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction(nameof(Login));
    }

    // ----------------------------------------------------
    // DASHBOARD
    // ----------------------------------------------------

    [HttpGet("Dashboard")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin,Admin")]
    public async Task<IActionResult> Dashboard()
    {
        var isSuperAdmin = User.IsInRole("SuperAdmin");
        var categoryId = GetAdminCategoryId();

        var eventsQuery = _db.Events
            .Include(e => e.Category)
            .Include(e => e.Registrations)
            .AsQueryable();

        if (!isSuperAdmin && categoryId.HasValue)
        {
            eventsQuery = eventsQuery.Where(e => e.CategoryId == categoryId.Value);
        }

        var totalEvents = await eventsQuery.CountAsync();
        var activeEvents = await eventsQuery.CountAsync(e => e.IsActive && e.EventDate >= DateTime.UtcNow);
        var totalRegistrations = await eventsQuery.SelectMany(e => e.Registrations).CountAsync();
        var checkedInCount = await eventsQuery.SelectMany(e => e.Registrations).CountAsync(r => r.CheckedInAt != null);
        var totalCategories = await _db.Categories.CountAsync(c => c.IsActive);

        ViewBag.Stats = new
        {
            TotalEvents = totalEvents,
            ActiveEvents = activeEvents,
            TotalRegistrations = totalRegistrations,
            CheckedInCount = checkedInCount,
            TotalCategories = totalCategories
        };

        ViewBag.RecentEvents = await eventsQuery
            .OrderByDescending(e => e.EventDate)
            .Take(8)
            .ToListAsync();

        return View();
    }

    // ----------------------------------------------------
    // EVENTS MANAGEMENT
    // ----------------------------------------------------

    [HttpGet("Events")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin,Admin")]
    public async Task<IActionResult> Events([FromQuery] int? categoryId = null)
    {
        var isSuperAdmin = User.IsInRole("SuperAdmin");
        var adminCatId = GetAdminCategoryId();

        var query = _db.Events
            .Include(e => e.Category)
            .Include(e => e.Registrations)
            .AsQueryable();

        if (!isSuperAdmin && adminCatId.HasValue)
        {
            query = query.Where(e => e.CategoryId == adminCatId.Value);
        }
        else if (isSuperAdmin && categoryId.HasValue && categoryId.Value > 0)
        {
            query = query.Where(e => e.CategoryId == categoryId.Value);
        }

        ViewBag.Categories = await _db.Categories.Where(c => c.IsActive).OrderBy(c => c.Name).ToListAsync();
        ViewBag.SelectedCategoryId = categoryId;

        var events = await query.OrderByDescending(e => e.EventDate).ToListAsync();
        return View(events);
    }

    [HttpPost("CreateEvent")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin,Admin")]
    public async Task<IActionResult> CreateEvent([FromForm] string title, [FromForm] string? description, [FromForm] DateTime eventDate, [FromForm] string location, [FromForm] int? categoryId)
    {
        var isSuperAdmin = User.IsInRole("SuperAdmin");
        var targetCatId = categoryId.GetValueOrDefault(1);

        if (!isSuperAdmin)
        {
            var adminCatId = GetAdminCategoryId();
            if (adminCatId.HasValue)
            {
                targetCatId = adminCatId.Value;
            }
        }

        var ev = new Event
        {
            Title = title.Trim(),
            Description = description?.Trim(),
            EventDate = DateTime.SpecifyKind(eventDate, DateTimeKind.Utc),
            Location = location.Trim(),
            CategoryId = targetCatId,
            IsActive = true
        };

        _db.Events.Add(ev);
        await _db.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Event \"{ev.Title}\" scheduled successfully!";
        return RedirectToAction(nameof(Events));
    }

    [HttpPost("DeleteEvent")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin,Admin")]
    public async Task<IActionResult> DeleteEvent([FromForm] int id)
    {
        var ev = await _db.Events.FindAsync(id);
        if (ev == null)
        {
            TempData["ErrorMessage"] = "Event not found.";
            return RedirectToAction(nameof(Events));
        }

        if (!User.IsInRole("SuperAdmin"))
        {
            var adminCatId = GetAdminCategoryId();
            if (adminCatId.HasValue && ev.CategoryId != adminCatId.Value)
            {
                TempData["ErrorMessage"] = "Unauthorized. You cannot delete events outside your assigned category.";
                return RedirectToAction(nameof(Events));
            }
        }

        _db.Events.Remove(ev);
        await _db.SaveChangesAsync();

        TempData["SuccessMessage"] = "Event deleted successfully.";
        return RedirectToAction(nameof(Events));
    }

    [HttpGet("EventAttendees/{id:int}")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin,Admin")]
    public async Task<IActionResult> EventAttendees(int id)
    {
        var ev = await _db.Events
            .Include(e => e.Category)
            .Include(e => e.Registrations)
                .ThenInclude(r => r.User)
            .FirstOrDefaultAsync(e => e.Id == id);

        if (ev == null)
        {
            TempData["ErrorMessage"] = "Event not found.";
            return RedirectToAction(nameof(Events));
        }

        if (!User.IsInRole("SuperAdmin"))
        {
            var adminCatId = GetAdminCategoryId();
            if (adminCatId.HasValue && ev.CategoryId != adminCatId.Value)
            {
                TempData["ErrorMessage"] = "Unauthorized. You cannot view attendees for events outside your assigned category.";
                return RedirectToAction(nameof(Events));
            }
        }

        return View(ev);
    }

    [HttpPost("RemoveAttendee")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin,Admin")]
    public async Task<IActionResult> RemoveAttendee([FromForm] int registrationId, [FromForm] int eventId)
    {
        var reg = await _db.Registrations
            .Include(r => r.Event)
            .FirstOrDefaultAsync(r => r.Id == registrationId);

        if (reg != null)
        {
            if (!User.IsInRole("SuperAdmin"))
            {
                var adminCatId = GetAdminCategoryId();
                if (adminCatId.HasValue && reg.Event.CategoryId != adminCatId.Value)
                {
                    TempData["ErrorMessage"] = "Unauthorized action.";
                    return RedirectToAction(nameof(EventAttendees), new { id = eventId });
                }
            }

            _db.Registrations.Remove(reg);
            await _db.SaveChangesAsync();
            TempData["SuccessMessage"] = "Attendee registration removed.";
        }

        return RedirectToAction(nameof(EventAttendees), new { id = eventId });
    }

    // ----------------------------------------------------
    // ADMINS MANAGEMENT (SuperAdmin only)
    // ----------------------------------------------------

    [HttpGet("Admins")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin")]
    public async Task<IActionResult> Admins()
    {
        var admins = await _db.Users
            .Include(u => u.AssignedCategory)
            .Where(u => u.Role == "SuperAdmin" || u.Role == "Admin")
            .OrderBy(u => u.Role == "SuperAdmin" ? 0 : 1)
            .ThenBy(u => u.FullName)
            .ToListAsync();

        ViewBag.Categories = await _db.Categories.Where(c => c.IsActive).OrderBy(c => c.Name).ToListAsync();
        return View(admins);
    }

    [HttpPost("CreateAdmin")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin")]
    public async Task<IActionResult> CreateAdmin([FromForm] string fullName, [FromForm] string email, [FromForm] string password, [FromForm] int categoryId)
    {
        var normalizedEmail = email.Trim().ToLowerInvariant();
        if (await _db.Users.AnyAsync(u => u.Email == normalizedEmail))
        {
            TempData["ErrorMessage"] = "An account with this email address already exists.";
            return RedirectToAction(nameof(Admins));
        }

        var newAdmin = new User
        {
            FullName = fullName.Trim(),
            Email = normalizedEmail,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
            Role = "Admin",
            AssignedCategoryId = categoryId,
            CreatedAt = DateTime.UtcNow
        };

        _db.Users.Add(newAdmin);
        await _db.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Category Admin account created for \"{newAdmin.FullName}\".";
        return RedirectToAction(nameof(Admins));
    }

    [HttpPost("DeleteAdmin")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin")]
    public async Task<IActionResult> DeleteAdmin([FromForm] int id)
    {
        var admin = await _db.Users.FindAsync(id);
        if (admin != null)
        {
            if (admin.Role == "SuperAdmin")
            {
                TempData["ErrorMessage"] = "The SuperAdmin account cannot be deleted.";
                return RedirectToAction(nameof(Admins));
            }

            _db.Users.Remove(admin);
            await _db.SaveChangesAsync();
            TempData["SuccessMessage"] = "Admin account revoked.";
        }

        return RedirectToAction(nameof(Admins));
    }

    // ----------------------------------------------------
    // CATEGORIES MANAGEMENT (SuperAdmin only)
    // ----------------------------------------------------

    [HttpGet("Categories")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin")]
    public async Task<IActionResult> Categories()
    {
        var categories = await _db.Categories
            .Include(c => c.Events)
            .Include(c => c.AssignedAdmins)
            .OrderBy(c => c.Name)
            .ToListAsync();

        return View(categories);
    }

    [HttpPost("CreateCategory")]
    [Authorize(AuthenticationSchemes = CookieAuthenticationDefaults.AuthenticationScheme, Roles = "SuperAdmin")]
    public async Task<IActionResult> CreateCategory([FromForm] string name, [FromForm] string? slug, [FromForm] string? description, [FromForm] string colorHex)
    {
        var targetSlug = string.IsNullOrWhiteSpace(slug)
            ? name.Trim().ToLowerInvariant().Replace(" ", "-")
            : slug.Trim().ToLowerInvariant();

        if (await _db.Categories.AnyAsync(c => c.Name == name.Trim() || c.Slug == targetSlug))
        {
            TempData["ErrorMessage"] = "A category with this name or slug already exists.";
            return RedirectToAction(nameof(Categories));
        }

        var cat = new Category
        {
            Name = name.Trim(),
            Slug = targetSlug,
            Description = description?.Trim(),
            ColorHex = string.IsNullOrWhiteSpace(colorHex) ? "#6C63FF" : colorHex.Trim(),
            IsActive = true
        };

        _db.Categories.Add(cat);
        await _db.SaveChangesAsync();

        TempData["SuccessMessage"] = $"Category \"{cat.Name}\" created successfully.";
        return RedirectToAction(nameof(Categories));
    }

    private int? GetAdminCategoryId()
    {
        var claim = User.FindFirst("CategoryId")?.Value;
        return int.TryParse(claim, out var id) ? id : null;
    }
}
