using EventPassApi.Data;
using EventPassApi.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EventPassApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CategoriesController : ControllerBase
{
    private readonly AppDbContext _db;

    public CategoriesController(AppDbContext db)
    {
        _db = db;
    }

    /// <summary>
    /// Gets all active categories.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var categories = await _db.Categories
            .Where(c => c.IsActive)
            .OrderBy(c => c.Name)
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.Slug,
                c.Description,
                c.ColorHex,
                c.IconName,
                EventCount = c.Events.Count(e => e.IsActive)
            })
            .ToListAsync();

        return Ok(categories);
    }

    /// <summary>
    /// Gets category by ID.
    /// </summary>
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var cat = await _db.Categories.FindAsync(id);
        if (cat == null) return NotFound(new { message = $"Category {id} not found." });

        return Ok(cat);
    }

    /// <summary>
    /// Creates a new category (SuperAdmin only).
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "SuperAdmin")]
    public async Task<IActionResult> Create([FromBody] Category request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest(new { message = "Category name is required." });
        }

        var slug = string.IsNullOrWhiteSpace(request.Slug)
            ? request.Name.Trim().ToLowerInvariant().Replace(" ", "-")
            : request.Slug.Trim().ToLowerInvariant();

        if (await _db.Categories.AnyAsync(c => c.Name == request.Name.Trim() || c.Slug == slug))
        {
            return Conflict(new { message = "A category with this name or slug already exists." });
        }

        var cat = new Category
        {
            Name = request.Name.Trim(),
            Slug = slug,
            Description = request.Description?.Trim(),
            ColorHex = string.IsNullOrWhiteSpace(request.ColorHex) ? "#6C63FF" : request.ColorHex.Trim(),
            IconName = string.IsNullOrWhiteSpace(request.IconName) ? "event" : request.IconName.Trim(),
            IsActive = true
        };

        _db.Categories.Add(cat);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = cat.Id }, cat);
    }
}
