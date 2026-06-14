using MarketOurs.Data;
using MarketOurs.DataAPI.Configs;
using MarketOurs.DataAPI.Repos;
using MarketOurs.DataAPI.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Moq;
using StackExchange.Redis;

namespace MarketOurs.Test.Services;

/// <summary>
/// FollowService 缓存一致性回归测试。
///
/// 背景：历史 bug —— 关系计数走 Redis Set，但 Set 通过增量 SetAdd/SetRemove 维护，
/// 在冷启动 / TTL 过期 / 屏蔽路径下会变成“残缺集合”，导致 SetLength 计数错乱
/// （粉丝数莫名跳变、取关后仍出现在列表中）。
///
/// 修复后的核心不变量（这些测试守护它）：
///   Redis 中的关系集合要么是数据库的“完整镜像”，要么不存在。
///   - key 存在  → 直接用其成员计数；
///   - key 不存在 → 从数据库全量重建整个集合，绝不返回残缺值。
/// </summary>
[TestFixture]
public class FollowServiceTests
{
    private Mock<IConnectionMultiplexer> _mockRedis;
    private Mock<IDatabase> _mockDatabase;
    private Mock<IUserRepo> _mockUserRepo;
    private Mock<ILockService> _mockLockService;
    private IMemoryCache _memoryCache;
    private FollowService _service;

    [SetUp]
    public void Setup()
    {
        _mockRedis = new Mock<IConnectionMultiplexer>();
        _mockDatabase = new Mock<IDatabase>();
        _mockUserRepo = new Mock<IUserRepo>();
        _mockLockService = new Mock<ILockService>();
        _memoryCache = new MemoryCache(new MemoryCacheOptions());

        _mockRedis.Setup(r => r.GetDatabase(It.IsAny<int>(), It.IsAny<object>()))
            .Returns(_mockDatabase.Object);
        var redisList = new List<IConnectionMultiplexer> { _mockRedis.Object };

        // DbContextFactory 仅被写路径使用；本测试只覆盖读路径，给一个不会被调用的 mock 即可。
        var mockFactory = new Mock<IDbContextFactory<MarketContext>>();

        _service = new FollowService(
            _mockUserRepo.Object,
            mockFactory.Object,
            redisList,
            _mockLockService.Object,
            _memoryCache,
            new Mock<ILogger<FollowService>>().Object);
    }

    [TearDown]
    public void TearDown() => _memoryCache.Dispose();

    [Test]
    public async Task GetFollowStats_WhenFollowersKeyExists_UsesRedisSetLength()
    {
        // Arrange：followers 集合已缓存，含 2 个完整成员
        const string userId = "userB";
        var followersKey = CacheKeys.UserFollowers(userId);
        var followingKey = CacheKeys.UserFollowing(userId);

        _mockDatabase.Setup(db => db.SetLengthAsync(followersKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(2);
        _mockDatabase.Setup(db => db.SetLengthAsync(followingKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(0);
        _mockDatabase.Setup(db => db.KeyExistsAsync(followingKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(true);

        // Act
        var stats = await _service.GetFollowStatsAsync(userId);

        // Assert：粉丝数 = Redis 集合成员数
        Assert.That(stats.FollowerCount, Is.EqualTo(2));
        // 未回源数据库，也不会把整集合读回内存
        _mockUserRepo.Verify(r => r.GetFollowerCountAsync(It.IsAny<string>()), Times.Never);
        _mockDatabase.Verify(db => db.SetMembersAsync(It.IsAny<RedisKey>(), It.IsAny<CommandFlags>()), Times.Never);
    }

    [Test]
    public async Task GetFollowStats_WhenFollowersKeyMissing_FallsBackToDatabaseCounts()
    {
        // Arrange：followers 集合缓存缺失时，直接回源数据库 count，不重建大集合。
        const string userId = "userB";
        var followersKey = CacheKeys.UserFollowers(userId);
        var followingKey = CacheKeys.UserFollowing(userId);

        _mockDatabase.Setup(db => db.SetLengthAsync(followersKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(0);
        _mockDatabase.Setup(db => db.SetLengthAsync(followingKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(0);
        _mockDatabase.Setup(db => db.KeyExistsAsync(followersKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(false);
        _mockDatabase.Setup(db => db.KeyExistsAsync(followingKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(false);

        _mockUserRepo.Setup(r => r.GetFollowerCountAsync(userId)).ReturnsAsync(3);
        _mockUserRepo.Setup(r => r.GetFollowingCountAsync(userId)).ReturnsAsync(0);

        // Act
        var stats = await _service.GetFollowStatsAsync(userId);

        // Assert：粉丝数 = 数据库 count 值
        Assert.That(stats.FollowerCount, Is.EqualTo(3));
        _mockDatabase.Verify(
            db => db.SetAddAsync(It.IsAny<RedisKey>(), It.IsAny<RedisValue[]>(), It.IsAny<CommandFlags>()),
            Times.Never);
    }

    [Test]
    public async Task GetFollowStats_WhenViewerProvided_UsesRedisSetContainsWithoutLoadingWholeSet()
    {
        // Arrange：viewer 关注了 target。直接用 Redis SetContains 判断，不拉整集合。
        const string targetId = "userB";
        const string viewerId = "userA";
        var targetFollowersKey = CacheKeys.UserFollowers(targetId);
        var targetFollowingKey = CacheKeys.UserFollowing(targetId);
        var viewerFollowingKey = CacheKeys.UserFollowing(viewerId);
        var viewerBlockedKey = CacheKeys.UserBlocked(viewerId);
        var targetBlockedKey = CacheKeys.UserBlocked(targetId);

        _mockDatabase.Setup(db => db.SetLengthAsync(targetFollowersKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(1);
        _mockDatabase.Setup(db => db.SetLengthAsync(targetFollowingKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(0);
        _mockDatabase.Setup(db => db.KeyExistsAsync(targetFollowingKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(true);

        _mockDatabase.Setup(db => db.SetContainsAsync(viewerFollowingKey, targetId, It.IsAny<CommandFlags>()))
            .ReturnsAsync(true);
        _mockDatabase.Setup(db => db.SetContainsAsync(targetFollowingKey, viewerId, It.IsAny<CommandFlags>()))
            .ReturnsAsync(false);
        _mockDatabase.Setup(db => db.KeyExistsAsync(targetFollowingKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(true);

        _mockDatabase.Setup(db => db.SetContainsAsync(viewerBlockedKey, targetId, It.IsAny<CommandFlags>()))
            .ReturnsAsync(false);
        _mockDatabase.Setup(db => db.KeyExistsAsync(viewerBlockedKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(true);
        _mockDatabase.Setup(db => db.SetContainsAsync(targetBlockedKey, viewerId, It.IsAny<CommandFlags>()))
            .ReturnsAsync(false);
        _mockDatabase.Setup(db => db.KeyExistsAsync(targetBlockedKey, It.IsAny<CommandFlags>()))
            .ReturnsAsync(true);

        // Act
        var stats = await _service.GetFollowStatsAsync(targetId, viewerId);

        // Assert：基于 SetContains 正确判定 viewer 正在关注 target
        Assert.That(stats.IsFollowing, Is.True);
        _mockDatabase.Verify(db => db.SetMembersAsync(It.IsAny<RedisKey>(), It.IsAny<CommandFlags>()), Times.Never);
    }
}
