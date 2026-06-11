using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace MarketOurs.DataAPI.Services;

public class LocalStorageService(IWebHostEnvironment environment, ILogger<LocalStorageService> logger) : IStorageService
{
    private readonly string _uploadRoot = Path.Combine(environment.WebRootPath ?? "wwwroot", "uploads");

    public async Task<string> SaveFileAsync(IFormFile file, string subFolder = "uploads")
    {
        if (file == null || file.Length == 0)
            throw new ArgumentException("文件为空");

        if (!Directory.Exists(_uploadRoot))
        {
            Directory.CreateDirectory(_uploadRoot);
        }

        var targetFolder = Path.Combine(_uploadRoot, subFolder);
        if (!Directory.Exists(targetFolder))
        {
            Directory.CreateDirectory(targetFolder);
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        var fileName = $"{Guid.NewGuid():N}{extension}";
        var filePath = Path.Combine(targetFolder, fileName);

        await using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        logger.LogInformation("文件已保存到本地: {FilePath}", filePath);
        return $"/uploads/{subFolder}/{fileName}".Replace("\\", "/");
    }

    public Task<bool> DeleteFileAsync(string fileUrl)
    {
        if (string.IsNullOrEmpty(fileUrl)) return Task.FromResult(false);

        try
        {
            var relativePath = fileUrl.TrimStart('/');
            var filePath = Path.Combine(environment.WebRootPath ?? "wwwroot", relativePath);

            if (File.Exists(filePath))
            {
                File.Delete(filePath);
                logger.LogInformation("文件已删除: {FilePath}", filePath);
                return Task.FromResult(true);
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "删除文件失败: {FileUrl}", fileUrl);
        }

        return Task.FromResult(false);
    }

    public async Task<int> DeleteFilesAsync(IEnumerable<string> fileUrls)
    {
        var count = 0;
        foreach (var url in fileUrls)
        {
            if (await DeleteFileAsync(url)) count++;
        }
        logger.LogInformation("批量删除完成: {Count}/{Total}", count, fileUrls.Count());
        return count;
    }
}