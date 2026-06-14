using MarketOurs.Data.DataModels;
using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Repos;
using MarketOurs.DataAPI.Services;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using StackExchange.Redis;

namespace MarketOurs.Test.Services;

[TestFixture]
public class PostServiceTests
{
    private Mock<IPostRepo> _mockPostRepo;
    private Mock<ICommentRepo> _mockCommentRepo;
    private Mock<IUserRepo> _mockUserRepo;
    private Mock<ILikeManager> _mockLikeManager;
    private Mock<IDistributedCache> _mockDistributedCache;
    private Mock<IMemoryCache> _mockMemoryCache;
    private Mock<IConnectionMultiplexer> _mockRedis;
    private Mock<IDatabase> _mockDatabase;
    private Mock<ILogger<PostService>> _mockLogger;
    private Mock<ILogger<UploadKeyService>> _mockUploadKeyLogger;
    private UploadKeyService _uploadKeyService;
    private PostService _postService;

    [SetUp]
    public void Setup()
    {
        _mockPostRepo = new Mock<IPostRepo>();
        _mockCommentRepo = new Mock<ICommentRepo>();
        _mockUserRepo = new Mock<IUserRepo>();
        _mockLikeManager = new Mock<ILikeManager>();
        _mockDistributedCache = new Mock<IDistributedCache>();
        _mockMemoryCache = new Mock<IMemoryCache>();
        _mockRedis = new Mock<IConnectionMultiplexer>();
        _mockDatabase = new Mock<IDatabase>();
        _mockLogger = new Mock<ILogger<PostService>>();
        _mockUploadKeyLogger = new Mock<ILogger<UploadKeyService>>();

        _mockRedis.Setup(r => r.GetDatabase(It.IsAny<int>(), It.IsAny<object>())).Returns(_mockDatabase.Object);
        var redisList = new List<IConnectionMultiplexer> { _mockRedis.Object };
        _uploadKeyService = new UploadKeyService(
            new MemoryDistributedCache(Options.Create(new MemoryDistributedCacheOptions())),
            redisList,
            _mockUploadKeyLogger.Object);

        // Setup MemoryCache mock
        object? expectedValue = null;
        _mockMemoryCache
            .Setup(m => m.TryGetValue(It.IsAny<object>(), out expectedValue))
            .Returns(false);
        _mockMemoryCache
            .Setup(m => m.CreateEntry(It.IsAny<object>()))
            .Returns(new Mock<ICacheEntry>().Object);
        _mockLikeManager
            .Setup(m => m.GetPostCountsBatchAsync(
                It.IsAny<IReadOnlyCollection<string>>(),
                It.IsAny<Func<string, string>>(),
                It.IsAny<IReadOnlyDictionary<string, int>>()))
            .ReturnsAsync((IReadOnlyCollection<string> ids, Func<string, string> _, IReadOnlyDictionary<string, int> fallbacks) =>
                ids.ToDictionary(id => id, id => fallbacks.TryGetValue(id, out var value) ? value : 0));
        _mockLikeManager
            .Setup(m => m.GetCommentCountsBatchAsync(
                It.IsAny<IReadOnlyCollection<string>>(),
                It.IsAny<Func<string, string>>(),
                It.IsAny<IReadOnlyDictionary<string, int>>()))
            .ReturnsAsync((IReadOnlyCollection<string> ids, Func<string, string> _, IReadOnlyDictionary<string, int> fallbacks) =>
                ids.ToDictionary(id => id, id => fallbacks.TryGetValue(id, out var value) ? value : 0));
        _mockLikeManager
            .Setup(m => m.GetPostReactionStateBatchAsync(It.IsAny<IReadOnlyCollection<string>>(), It.IsAny<string>()))
            .ReturnsAsync(new Dictionary<string, (bool IsLiked, bool IsDisliked)>());
        _mockPostRepo
            .Setup(r => r.GetAllDtosAsync(It.IsAny<int>(), It.IsAny<int>(), It.IsAny<string?>()))
            .ReturnsAsync([]);
        _mockPostRepo
            .Setup(r => r.GetByUserDtosAsync(It.IsAny<string>(), It.IsAny<int>(), It.IsAny<int>()))
            .ReturnsAsync([]);
        _mockPostRepo
            .Setup(r => r.GetHotDtosAsync(It.IsAny<int>()))
            .ReturnsAsync([]);
        _mockPostRepo
            .Setup(r => r.SearchDtosAsync(It.IsAny<string>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<string?>()))
            .ReturnsAsync([]);

        _postService = new PostService(
            _mockPostRepo.Object,
            _mockCommentRepo.Object,
            _mockUserRepo.Object,
            _mockLikeManager.Object,
            _mockDistributedCache.Object,
            _mockMemoryCache.Object,
            redisList,
            _mockLogger.Object,
            _uploadKeyService,
            null!
        );
    }

    [Test]
    public async Task GetAllAsync_ShouldReturnAllPostsWithDynamicData()
    {
        // Arrange
        var posts = new List<PostModel>
        {
            new PostModel { Id = "1", Title = "Post 1", Content = "Content 1" },
            new PostModel { Id = "2", Title = "Post 2", Content = "Content 2" }
        };
        _mockPostRepo.Setup(r => r.CountAsync(null)).ReturnsAsync(2);
        _mockPostRepo.Setup(r => r.GetAllDtosAsync(It.IsAny<int>(), It.IsAny<int>(), null))
            .ReturnsAsync(posts.Select(PostService.MapToDto).ToList());

        _mockLikeManager.Setup(m => m.GetPostLikesAsync(It.IsAny<string>(), It.IsAny<int>())).ReturnsAsync(10);
        _mockLikeManager.Setup(m => m.GetPostDislikesAsync(It.IsAny<string>(), It.IsAny<int>())).ReturnsAsync(2);
        _mockLikeManager
            .Setup(m => m.GetPostCountsBatchAsync(It.IsAny<IReadOnlyCollection<string>>(), It.IsAny<Func<string, string>>(), It.IsAny<IReadOnlyDictionary<string, int>>()))
            .ReturnsAsync((IReadOnlyCollection<string> ids, Func<string, string> keyFactory, IReadOnlyDictionary<string, int> _) =>
            {
                var value = keyFactory("1").EndsWith(":likes", StringComparison.Ordinal) ? 10 : 2;
                return ids.ToDictionary(id => id, _ => value);
            });

        _mockDatabase.Setup(db => db.StringGetAsync(It.IsAny<RedisKey>(), It.IsAny<CommandFlags>()))
            .ReturnsAsync(new RedisValue("100"));

        // Act
        var result = await _postService.GetAllAsync(new PaginationParams());

        // Assert
        Assert.That(result, Is.Not.Null);
        Assert.That(result.Items.Count, Is.EqualTo(2));
        Assert.That(result.Items[0].Id, Is.EqualTo("1"));
        Assert.That(result.Items[0].Likes, Is.EqualTo(10));
        Assert.That(result.Items[0].Dislikes, Is.EqualTo(2));
        Assert.That(result.Items[0].Watch, Is.EqualTo(100));
    }

    [Test]
    public async Task GetAllAsync_WithTagId_ShouldPassTrimmedFilterToRepo()
    {
        _mockPostRepo.Setup(r => r.CountAsync("tag-1")).ReturnsAsync(0);
        _mockPostRepo.Setup(r => r.GetAllDtosAsync(1, 10, "tag-1")).ReturnsAsync([]);

        await _postService.GetAllAsync(new PaginationParams { TagId = "  tag-1  " });

        _mockPostRepo.Verify(r => r.CountAsync("tag-1"), Times.Once);
        _mockPostRepo.Verify(r => r.GetAllDtosAsync(1, 10, "tag-1"), Times.Once);
    }

    [Test]
    public async Task GetByUserIdAsync_ShouldReturnPagedPostsWithDynamicData()
    {
        var posts = new List<PostModel>
        {
            new PostModel { Id = "1", Title = "Post 1", Content = "Content 1", UserId = "user-1" },
            new PostModel { Id = "2", Title = "Post 2", Content = "Content 2", UserId = "user-1" }
        };

        _mockPostRepo.Setup(r => r.CountByUserIdAsync("user-1")).ReturnsAsync(2);
        _mockPostRepo.Setup(r => r.GetByUserDtosAsync("user-1", It.IsAny<int>(), It.IsAny<int>()))
            .ReturnsAsync(posts.Select(PostService.MapToDto).ToList());
        _mockLikeManager.Setup(m => m.GetPostLikesAsync(It.IsAny<string>(), It.IsAny<int>())).ReturnsAsync(3);
        _mockLikeManager.Setup(m => m.GetPostDislikesAsync(It.IsAny<string>(), It.IsAny<int>())).ReturnsAsync(1);
        _mockLikeManager
            .Setup(m => m.GetPostCountsBatchAsync(It.IsAny<IReadOnlyCollection<string>>(), It.IsAny<Func<string, string>>(), It.IsAny<IReadOnlyDictionary<string, int>>()))
            .ReturnsAsync((IReadOnlyCollection<string> ids, Func<string, string> keyFactory, IReadOnlyDictionary<string, int> _) =>
            {
                var value = keyFactory("1").EndsWith(":likes", StringComparison.Ordinal) ? 3 : 1;
                return ids.ToDictionary(id => id, _ => value);
            });
        _mockDatabase.Setup(db => db.StringGetAsync(It.IsAny<RedisKey>(), It.IsAny<CommandFlags>()))
            .ReturnsAsync(new RedisValue("9"));

        var result = await _postService.GetByUserIdAsync("user-1", new PaginationParams());

        Assert.That(result.Items.Count, Is.EqualTo(2));
        Assert.That(result.TotalCount, Is.EqualTo(2));
        Assert.That(result.Items.All(x => x.UserId == "user-1"), Is.True);
        Assert.That(result.Items[0].Likes, Is.EqualTo(3));
        Assert.That(result.Items[0].Watch, Is.EqualTo(9));
    }

    [Test]
    public async Task GetByIdAsync_WhenPostExists_ShouldReturnPostDto()
    {
        // Arrange
        var post = new PostModel { Id = "1", Title = "Test Post" };
        _mockPostRepo.Setup(r => r.GetReviewedByIdAsync("1")).ReturnsAsync(post);

        // Mock redis missing the distributed cache
        _mockDistributedCache.Setup(d => d.GetAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((byte[]?)null);

        // Act
        var result = await _postService.GetByIdAsync("1");

        // Assert
        Assert.That(result, Is.Not.Null);
        Assert.That(result!.Id, Is.EqualTo("1"));
        Assert.That(result.Title, Is.EqualTo("Test Post"));
    }

    [Test]
    public async Task CreateAsync_WithValidUser_ShouldCreatePost()
    {
        // Arrange
        var createDto = new PostCreateDto { UserId = "1", Title = "New Post", Content = "New Content" };
        var user = new UserModel { Id = "1", Name = "User1" };
        _mockUserRepo.Setup(r => r.GetByIdAsync("1")).ReturnsAsync(user);

        PostModel? createdPost = null;
        _mockPostRepo.Setup(r => r.CreateAsync(It.IsAny<PostModel>()))
            .Callback<PostModel>(p => createdPost = p)
            .Returns(Task.CompletedTask);

        // Act
        var result = await _postService.CreateAsync(createDto);

        // Assert
        Assert.That(result, Is.Not.Null);
        Assert.That(createdPost, Is.Not.Null);
        Assert.That(createdPost!.Title, Is.EqualTo("New Post"));
        Assert.That(createdPost.Content, Is.EqualTo("New Content"));
        Assert.That(createdPost.UserId, Is.EqualTo("1"));
    }

    [Test]
    public async Task CreateAsync_WithUploadKeyTrackedImages_ShouldPersistTrackedImages()
    {
        // Arrange
        var (uploadKey, _) = await _uploadKeyService.GenerateKeyAsync();
        await _uploadKeyService.TrackFilesAsync(uploadKey, ["https://cdn.example.com/post-image.webp"]);

        var createDto = new PostCreateDto
        {
            UserId = "1",
            Title = "New Post",
            Content = "New Content",
            UploadKey = uploadKey
        };
        var user = new UserModel { Id = "1", Name = "User1" };
        _mockUserRepo.Setup(r => r.GetByIdAsync("1")).ReturnsAsync(user);

        PostModel? createdPost = null;
        _mockPostRepo.Setup(r => r.CreateAsync(It.IsAny<PostModel>()))
            .Callback<PostModel>(p =>
            {
                p.Id = "post-1";
                createdPost = p;
            })
            .Returns(Task.CompletedTask);
        _mockPostRepo.Setup(r => r.UpdateAsync(It.IsAny<PostModel>())).Returns(Task.CompletedTask);

        // Act
        var result = await _postService.CreateAsync(createDto);

        // Assert
        Assert.That(result.Images, Is.EqualTo(new[] { "https://cdn.example.com/post-image.webp" }));
        Assert.That(createdPost!.Images, Is.EqualTo(new[] { "https://cdn.example.com/post-image.webp" }));
        _mockPostRepo.Verify(r => r.UpdateAsync(It.Is<PostModel>(p => p.Images.Count == 1)), Times.Once);
    }

    [Test]
    public async Task UpdateAsync_WhenPostExists_ShouldUpdatePost()
    {
        // Arrange
        var post = new PostModel { Id = "1", Title = "Old Title", Content = "Old Content" };
        var updateDto = new PostUpdateDto { Title = "New Title", Content = "New Content" };

        _mockPostRepo.Setup(r => r.GetByIdAsync("1")).ReturnsAsync(post);
        _mockPostRepo.Setup(r => r.UpdateAsync(It.IsAny<PostModel>())).Returns(Task.CompletedTask);

        // Act
        var result = await _postService.UpdateAsync("1", updateDto);

        // Assert
        Assert.That(result, Is.Not.Null);
        Assert.That(result!.Title, Is.EqualTo("New Title"));
        Assert.That(result.Content, Is.EqualTo("New Content"));
        Assert.That(post.Title, Is.EqualTo("New Title"));
    }

    [Test]
    public async Task DeleteAsync_ShouldCallDeleteOnRepoAndInvalidateCache()
    {
        // Arrange
        _mockPostRepo.Setup(r => r.GetByIdAsync("1")).ReturnsAsync(new PostModel { Id = "1" });
        _mockPostRepo.Setup(r => r.DeleteAsync("1")).Returns(Task.CompletedTask);

        // Act
        await _postService.DeleteAsync("1");

        // Assert
        _mockPostRepo.Verify(r => r.DeleteAsync("1"), Times.Once);
        _mockMemoryCache.Verify(m => m.Remove(It.IsAny<object>()), Times.AtLeastOnce);
    }

    [Test]
    public async Task SearchAsync_WithEmptyKeyword_ReturnsEmptyPageWithoutRepoSearch()
    {
        var result = await _postService.SearchAsync(new PaginationParams { Keyword = "   " });

        Assert.That(result.Items, Is.Empty);
        Assert.That(result.TotalCount, Is.EqualTo(0));
        _mockPostRepo.Verify(r => r.SearchCountAsync(It.IsAny<string>(), It.IsAny<string?>()), Times.Never);
        _mockPostRepo.Verify(r => r.SearchAsync(It.IsAny<string>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<string?>()), Times.Never);
    }

    [Test]
    public async Task SearchAsync_WithKeyword_TrimsKeywordAndReturnsDynamicData()
    {
        var posts = new List<PostModel>
        {
            new() { Id = "post-1", Title = "二手单反相机", Content = "9 成新", IsReview = true }
        };

        _mockPostRepo.Setup(r => r.SearchCountAsync("相机", null)).ReturnsAsync(1);
        _mockPostRepo.Setup(r => r.SearchDtosAsync("相机", 2, 5, null))
            .ReturnsAsync(posts.Select(PostService.MapToDto).ToList());
        _mockLikeManager.Setup(m => m.GetPostLikesAsync("post-1", It.IsAny<int>())).ReturnsAsync(7);
        _mockLikeManager.Setup(m => m.GetPostDislikesAsync("post-1", It.IsAny<int>())).ReturnsAsync(1);
        _mockLikeManager
            .Setup(m => m.GetPostCountsBatchAsync(It.IsAny<IReadOnlyCollection<string>>(), It.IsAny<Func<string, string>>(), It.IsAny<IReadOnlyDictionary<string, int>>()))
            .ReturnsAsync((IReadOnlyCollection<string> ids, Func<string, string> keyFactory, IReadOnlyDictionary<string, int> _) =>
            {
                var value = keyFactory("post-1").EndsWith(":likes", StringComparison.Ordinal) ? 7 : 1;
                return ids.ToDictionary(id => id, _ => value);
            });
        _mockDatabase.Setup(db => db.StringGetAsync(It.IsAny<RedisKey>(), It.IsAny<CommandFlags>()))
            .ReturnsAsync(RedisValue.Null);

        var result = await _postService.SearchAsync(new PaginationParams
        {
            Keyword = "  相机  ",
            PageIndex = 2,
            PageSize = 5
        });

        Assert.That(result.TotalCount, Is.EqualTo(1));
        Assert.That(result.Items, Has.Count.EqualTo(1));
        Assert.That(result.Items[0].Title, Does.Contain("相机"));
        Assert.That(result.Items[0].Likes, Is.EqualTo(7));
        _mockPostRepo.Verify(r => r.SearchCountAsync("相机", null), Times.Once);
        _mockPostRepo.Verify(r => r.SearchDtosAsync("相机", 2, 5, null), Times.Once);
    }

    [Test]
    public async Task SearchAsync_WithKeywordAndTagId_ShouldPassTrimmedValuesToRepo()
    {
        _mockPostRepo.Setup(r => r.SearchCountAsync("相机", "tag-camera")).ReturnsAsync(0);
        _mockPostRepo.Setup(r => r.SearchDtosAsync("相机", 1, 10, "tag-camera")).ReturnsAsync([]);

        await _postService.SearchAsync(new PaginationParams
        {
            Keyword = " 相机 ",
            TagId = " tag-camera "
        });

        _mockPostRepo.Verify(r => r.SearchCountAsync("相机", "tag-camera"), Times.Once);
        _mockPostRepo.Verify(r => r.SearchDtosAsync("相机", 1, 10, "tag-camera"), Times.Once);
    }

    [Test]
    public async Task GetCommentsAsync_ForAnonymousUser_ShouldOnlyUseReviewedCommentsFromRepo()
    {
        var comments = new List<CommentModel>
        {
            new() { Id = "c1", PostId = "post-1", UserId = "user-1", Content = "公开评论", IsReview = true }
        };

        _mockPostRepo
            .Setup(r => r.GetCommentsAsync("post-1", null, false))
            .ReturnsAsync(comments);
        _mockLikeManager
            .Setup(m => m.GetCommentCountsBatchAsync(It.IsAny<IReadOnlyCollection<string>>(), It.IsAny<Func<string, string>>(), It.IsAny<IReadOnlyDictionary<string, int>>()))
            .ReturnsAsync(new Dictionary<string, int> { ["c1"] = 4 });

        var result = await _postService.GetCommentsAsync("post-1", "New", null, false);

        Assert.That(result, Has.Count.EqualTo(1));
        Assert.That(result[0].Id, Is.EqualTo("c1"));
        _mockPostRepo.Verify(r => r.GetCommentsAsync("post-1", null, false), Times.Once);
    }
}
