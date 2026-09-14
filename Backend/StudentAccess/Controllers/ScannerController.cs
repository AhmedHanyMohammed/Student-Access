using System.Security.Claims;
using EventPassApi.Dtos.Scans;
using EventPassApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace EventPassApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ScannerController : ControllerBase
{
    private readonly IScanService _scanService;

    public ScannerController(IScanService scanService)
    {
        _scanService = scanService;
    }

    /// <summary>
    /// Processes a scanned QR token and returns the check-in status:
    /// 'valid', 'already checked in', 'invalid', or 'inactive'.
    /// </summary>
    [HttpPost("scan")]
    [ProducesResponseType(typeof(ScanResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(object), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Scan([FromBody] ScanRequestDto request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        // If scannedBy was not passed in body, try to extract from authenticated user if available
        if (string.IsNullOrWhiteSpace(request.ScannedBy) && User.Identity?.IsAuthenticated == true)
        {
            request.ScannedBy = User.FindFirstValue(ClaimTypes.Name) 
                             ?? User.FindFirstValue(ClaimTypes.Email) 
                             ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        }

        var result = await _scanService.ProcessScanAsync(request);
        return Ok(result);
    }
}
