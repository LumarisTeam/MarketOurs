using System.ComponentModel.DataAnnotations;

namespace MarketOurs.DataAPI.Configs;

/// <summary>
/// JWT配置类，用于管理JWT相关配置项
/// </summary>
[Serializable]
public class JwtConfig
{
    /// <summary>
    /// 访问令牌过期时间（分钟），建议15-30分钟
    /// </summary>
    [Range(15, 30)]
    public int AccessTokenExpiryMinutes { get; set; } = 20;

    /// <summary>
    /// Web 刷新令牌过期时间（小时）
    /// </summary>
    [Range(24, 2160)]
    public int WebRefreshTokenExpiryHours { get; set; } = 72;

    /// <summary>
    /// Mobile 刷新令牌过期时间（小时）
    /// </summary>
    [Range(24, 2160)]
    public int MobileRefreshTokenExpiryHours { get; set; } = 720;

    /// <summary>
    /// Desktop 刷新令牌过期时间（小时）
    /// </summary>
    [Range(24, 2160)]
    public int DesktopRefreshTokenExpiryHours { get; set; } = 720;

    /// <summary>
    /// RSA私钥路径
    /// </summary>
    [Required]
    public string RsaPrivateKeyPath { get; set; } = "";

    /// <summary>
    /// RSA公钥路径
    /// </summary>
    [Required]
    public string RsaPublicKeyPath { get; set; } = "";

    /// <summary>
    /// 签发者
    /// </summary>
    [Required]
    public string Issuer { get; set; } = "iOS Club";

    /// <summary>
    /// 接收者
    /// </summary>
    [Required]
    public string Audience { get; set; } = "iOS Club";

    /// <summary>
    /// 密钥轮换周期（天）
    /// </summary>
    [Range(30, 365)]
    public int KeyRotationDays { get; set; } = 90;
}
