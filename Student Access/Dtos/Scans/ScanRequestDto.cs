using System.ComponentModel.DataAnnotations;

namespace EventPassApi.Dtos.Scans;

public class ScanRequestDto
{
    [Required]
    public string QrToken { get; set; } = string.Empty;

    /// <summary>
    /// Identifier of who/what performed the scan (staff account id,
    /// device name, gate id). Optional but recommended for auditing.
    /// </summary>
    public string? ScannedBy { get; set; }
}