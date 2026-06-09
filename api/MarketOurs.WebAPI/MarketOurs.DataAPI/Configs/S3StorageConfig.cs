namespace MarketOurs.DataAPI.Configs;

public class S3StorageConfig
{
    public string AccessKey { get; set; } = "";
    public string SecretKey { get; set; } = "";
    public string BucketName { get; set; } = "";
    public string Region { get; set; } = "us-east-1";
    public string? Endpoint { get; set; }
    public string BasePrefix { get; set; } = "uploads";
    public string? CdnBaseUrl { get; set; }
    public bool ForcePathStyle { get; set; }
}
