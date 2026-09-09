namespace MarketOurs.DataAPI.Configs;

/// <summary>
/// 热榜帖子的时间范围规则。
/// </summary>
public class HotListConfig
{
    public const string MaxPostAgeDaysEnvironmentVariable = "HOT_LIST_MAX_AGE_DAYS";

    /// <summary>
    /// 帖子发布超过此时长后不再进入热榜。
    /// </summary>
    /// <remarks>
    /// 通过 <c>HOT_LIST_MAX_AGE_DAYS</c> 环境变量配置，单位为天，在应用启动时读取一次。
    /// 未配置或配置无效时使用 7 天。
    /// </remarks>
    public TimeSpan MaxPostAge { get; set; } = TimeSpan.FromDays(30);
}
