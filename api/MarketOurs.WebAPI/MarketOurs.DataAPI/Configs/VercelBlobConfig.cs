namespace MarketOurs.DataAPI.Configs;

public class VercelBlobConfig
{
    public string Token { get; set; } = "";
    public string StoreId { get; set; } = "";
    public string Access { get; set; } = "public";
    public string BaseUrl { get; set; } = "uploads";
    public int CacheControlMaxAgeSeconds { get; set; } = 31536000;
}