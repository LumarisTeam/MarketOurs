namespace MarketOurs.Data.DTOs;

/// <summary>
/// 关注操作结果
/// </summary>
public record FollowToggleResult(
    bool IsFollowing,
    int FollowerCount,
    int FollowingCount
);

/// <summary>
/// 用户关系统计
/// </summary>
public class FollowStatsDto
{
    /// <summary>
    /// 粉丝数量
    /// </summary>
    public int FollowerCount { get; set; }

    /// <summary>
    /// 关注数量
    /// </summary>
    public int FollowingCount { get; set; }

    /// <summary>
    /// 查看者是否关注此用户
    /// </summary>
    public bool IsFollowing { get; set; }

    /// <summary>
    /// 此用户是否关注查看者
    /// </summary>
    public bool IsFollowedBy { get; set; }

    /// <summary>
    /// 查看者是否屏蔽此用户
    /// </summary>
    public bool IsBlocked { get; set; }

    /// <summary>
    /// 此用户是否屏蔽查看者
    /// </summary>
    public bool IsBlockedBy { get; set; }
}
