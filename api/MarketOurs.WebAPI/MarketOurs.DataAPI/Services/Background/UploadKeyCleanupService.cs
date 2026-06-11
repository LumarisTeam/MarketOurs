using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace MarketOurs.DataAPI.Services.Background;

/// <summary>
/// 定期清理过期的上传密钥及其关联的文件。
/// 上传密钥通过 Redis TTL 自动过期，此服务定期扫描并删除未被确认的孤立文件。
/// </summary>
public class UploadKeyCleanupService(
    IServiceScopeFactory scopeFactory,
    ILogger<UploadKeyCleanupService> logger) : BackgroundService
{
    private static readonly TimeSpan CleanupInterval = TimeSpan.FromMinutes(5);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("UploadKeyCleanupService started, interval: {Interval}min",
            CleanupInterval.TotalMinutes);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(CleanupInterval, stoppingToken);
                await CleanupExpiredKeysAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error during upload key cleanup cycle");
            }
        }

        logger.LogInformation("UploadKeyCleanupService stopped");
    }

    private async Task CleanupExpiredKeysAsync(CancellationToken ct)
    {
        using var scope = scopeFactory.CreateScope();
        var uploadKeyService = scope.ServiceProvider.GetRequiredService<UploadKeyService>();
        var storageService = scope.ServiceProvider.GetRequiredService<IStorageService>();

        var activeKeys = await uploadKeyService.GetActiveKeysAsync();
        if (activeKeys.Count == 0) return;

        logger.LogInformation("Scanning {Count} active upload keys for cleanup", activeKeys.Count);

        foreach (var key in activeKeys)
        {
            ct.ThrowIfCancellationRequested();
            // DeleteFilesByKeyAsync internally calls GetAndRemoveFilesAsync,
            // which atomically gets the file list and removes the key.
            // If the key has already expired in Redis, GetAndRemoveFilesAsync returns empty
            // and no files will be deleted — this is safe.
            await uploadKeyService.DeleteFilesByKeyAsync(key, storageService);
        }
    }
}
