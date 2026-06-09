using Amazon.S3;
using Amazon.S3.Model;
using MarketOurs.DataAPI.Configs;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace MarketOurs.DataAPI.Services;

public class S3StorageService(
    IAmazonS3 s3Client,
    LocalStorageService localStorageService,
    ILogger<S3StorageService> logger,
    S3StorageConfig config) : IStorageService
{
    public async Task<string> SaveFileAsync(IFormFile file, string subFolder = "uploads")
    {
        if (file == null || file.Length == 0)
            throw new ArgumentException("文件为空");

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        var fileName = $"{Guid.NewGuid():N}{extension}";
        var key = BuildKey(subFolder, fileName);

        await using var stream = file.OpenReadStream();
        var request = new PutObjectRequest
        {
            BucketName = config.BucketName,
            Key = key,
            InputStream = stream,
            ContentType = string.IsNullOrWhiteSpace(file.ContentType)
                ? "application/octet-stream"
                : file.ContentType,
            AutoCloseStream = false
        };

        var response = await s3Client.PutObjectAsync(request);

        if ((int)response.HttpStatusCode < 200 || (int)response.HttpStatusCode >= 300)
        {
            logger.LogError("S3 上传失败: {StatusCode}", response.HttpStatusCode);
            throw new InvalidOperationException($"上传到 S3 失败: {(int)response.HttpStatusCode}");
        }

        var url = BuildAccessUrl(key);
        logger.LogInformation("文件已上传到 S3: {Url}", url);
        return url;
    }

    public async Task<bool> DeleteFileAsync(string fileUrl)
    {
        if (string.IsNullOrWhiteSpace(fileUrl))
            return false;

        var key = ExtractKeyFromUrl(fileUrl);
        if (key == null)
            return await localStorageService.DeleteFileAsync(fileUrl);

        var request = new DeleteObjectRequest
        {
            BucketName = config.BucketName,
            Key = key
        };

        var response = await s3Client.DeleteObjectAsync(request);
        if ((int)response.HttpStatusCode >= 200 && (int)response.HttpStatusCode < 300)
        {
            logger.LogInformation("S3 文件已删除: {Key}", key);
            return true;
        }

        logger.LogError("S3 删除失败: {StatusCode}", response.HttpStatusCode);
        return false;
    }

    private string BuildKey(string subFolder, string fileName)
    {
        var parts = new[] { config.BasePrefix, subFolder.Trim('/'), fileName }
            .Where(part => !string.IsNullOrWhiteSpace(part));
        return string.Join('/', parts);
    }

    private string BuildAccessUrl(string key)
    {
        if (!string.IsNullOrWhiteSpace(config.CdnBaseUrl))
            return $"{config.CdnBaseUrl.TrimEnd('/')}/{key}";

        if (!string.IsNullOrWhiteSpace(config.Endpoint))
            return $"{config.Endpoint.TrimEnd('/')}/{config.BucketName}/{key}";

        return $"https://{config.BucketName}.s3.{config.Region}.amazonaws.com/{key}";
    }

    private string? ExtractKeyFromUrl(string fileUrl)
    {
        if (!Uri.TryCreate(fileUrl, UriKind.Absolute, out var uri))
            return null;

        if (!string.IsNullOrWhiteSpace(config.CdnBaseUrl) &&
            fileUrl.StartsWith(config.CdnBaseUrl, StringComparison.OrdinalIgnoreCase))
        {
            return fileUrl[config.CdnBaseUrl.TrimEnd('/').Length..].TrimStart('/');
        }

        if (uri.Host.Contains("s3") || uri.Host.Contains("amazonaws.com") ||
            (!string.IsNullOrWhiteSpace(config.Endpoint) &&
             fileUrl.StartsWith(config.Endpoint, StringComparison.OrdinalIgnoreCase)))
        {
            var path = uri.AbsolutePath.TrimStart('/');
            if (config.ForcePathStyle && path.StartsWith(config.BucketName + "/"))
                return path[(config.BucketName.Length + 1)..];
            return path;
        }

        return null;
    }
}
