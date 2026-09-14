using EventPassApi.Dtos.Scans;

namespace EventPassApi.Services;

public interface IScanService
{
    Task<ScanResultDto> ProcessScanAsync(ScanRequestDto request);
}