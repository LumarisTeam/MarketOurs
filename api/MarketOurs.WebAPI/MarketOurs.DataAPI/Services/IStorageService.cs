using Microsoft.AspNetCore.Http;

namespace MarketOurs.DataAPI.Services;

public interface IStorageService
{
    /// <summary>
    /// 保存文件并返回文件的可访问 URL
    /// </summary>
    Task<string> SaveFileAsync(IFormFile file, string subFolder = "uploads");

    /// <summary>
    /// 删除文件
    /// </summary>
    Task<bool> DeleteFileAsync(string fileUrl);
}