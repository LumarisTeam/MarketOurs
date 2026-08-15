using MarketOurs.Data.DataModels;
using MarketOurs.DataAPI.Repos;
using MarketOurs.DataAPI.Services;
using MarketOurs.DataAPI.Services.Background;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Moq;

namespace MarketOurs.Test.Services;

[TestFixture]
public class ReviewBackgroundServiceTests
{
    [Test]
    public async Task ExecuteAsync_WhenReviewingComment_ShouldUpdateCommentReviewOnly()
    {
        var queue = new ReviewMessageQueue();
        var notificationQueue = new NotificationMessageQueue();
        using var memoryCache = new MemoryCache(new MemoryCacheOptions { SizeLimit = 100 });
        var distributedCache = new Mock<IDistributedCache>();
        var logger = new Mock<ILogger<ReviewBackgroundService>>();

        var postRepo = new Mock<IPostRepo>();
        var commentRepo = new Mock<ICommentRepo>();
        var reviewService = new Mock<IReviewService>();

        commentRepo.Setup(r => r.GetByIdAsync("comment_1")).ReturnsAsync(new CommentModel
        {
            Id = "comment_1",
            PostId = "post_1",
            UserId = "user_1",
            Content = "test"
        });
        commentRepo.Setup(r => r.SetReviewStatusAsync("comment_1", true)).Returns(Task.CompletedTask);
        reviewService.Setup(r => r.Review(It.IsAny<string>())).ReturnsAsync(string.Empty);

        var serviceProvider = new Mock<IServiceProvider>();
        serviceProvider.Setup(sp => sp.GetService(typeof(IPostRepo))).Returns(postRepo.Object);
        serviceProvider.Setup(sp => sp.GetService(typeof(ICommentRepo))).Returns(commentRepo.Object);
        serviceProvider.Setup(sp => sp.GetService(typeof(IReviewService))).Returns(reviewService.Object);

        var scope = new Mock<IServiceScope>();
        scope.SetupGet(s => s.ServiceProvider).Returns(serviceProvider.Object);

        var scopeFactory = new Mock<IServiceScopeFactory>();
        scopeFactory.Setup(factory => factory.CreateScope()).Returns(scope.Object);

        var service = new TestableReviewBackgroundService(
            queue,
            scopeFactory.Object,
            notificationQueue,
            memoryCache,
            distributedCache.Object,
            logger.Object);

        var cts = new CancellationTokenSource();
        var runTask = service.RunAsync(cts.Token);
        await queue.EnqueueAsync(new ReviewMessage("comment_1", ReviewType.Comment));

        await Task.Delay(100);
        cts.Cancel();
        try
        {
            await runTask;
        }
        catch (OperationCanceledException)
        {
        }

        commentRepo.Verify(r => r.SetReviewStatusAsync("comment_1", true), Times.Once);
        postRepo.Verify(r => r.SetReviewStatusAsync(It.IsAny<string>(), It.IsAny<bool>()), Times.Never);
    }

    [Test]
    public async Task ExecuteAsync_WhenReviewingTeacherComment_ShouldUpdateReviewStatus()
    {
        var queue = new ReviewMessageQueue();
        var notificationQueue = new NotificationMessageQueue();
        using var memoryCache = new MemoryCache(new MemoryCacheOptions { SizeLimit = 100 });
        var distributedCache = new Mock<IDistributedCache>();
        var logger = new Mock<ILogger<ReviewBackgroundService>>();

        var teacherCommentRepo = new Mock<ITeacherCommentRepo>();
        var reviewService = new Mock<IReviewService>();

        teacherCommentRepo.Setup(r => r.GetByKeyAsync("teacher_comment_1")).ReturnsAsync(new TeacherCommentModel
        {
            Key = "teacher_comment_1",
            TeacherName = "张老师",
            CourseName = "高等数学",
            UserId = "user_1",
            Star = 4,
            Comment = "讲课清晰",
            Status = CommentReviewStatus.Pending
        });
        teacherCommentRepo
            .Setup(r => r.SetReviewStatusAsync("teacher_comment_1", false, "出现敏感词"))
            .Returns(Task.CompletedTask);
        reviewService.Setup(r => r.Review(It.IsAny<string>())).ReturnsAsync("出现敏感词");

        var serviceProvider = new Mock<IServiceProvider>();
        serviceProvider.Setup(sp => sp.GetService(typeof(ITeacherCommentRepo))).Returns(teacherCommentRepo.Object);
        serviceProvider.Setup(sp => sp.GetService(typeof(IReviewService))).Returns(reviewService.Object);

        var scope = new Mock<IServiceScope>();
        scope.SetupGet(s => s.ServiceProvider).Returns(serviceProvider.Object);

        var scopeFactory = new Mock<IServiceScopeFactory>();
        scopeFactory.Setup(factory => factory.CreateScope()).Returns(scope.Object);

        var service = new TestableReviewBackgroundService(
            queue,
            scopeFactory.Object,
            notificationQueue,
            memoryCache,
            distributedCache.Object,
            logger.Object);

        var cts = new CancellationTokenSource();
        var runTask = service.RunAsync(cts.Token);
        await queue.EnqueueAsync(new ReviewMessage("teacher_comment_1", ReviewType.TeacherComment));

        await Task.Delay(100);
        cts.Cancel();
        try
        {
            await runTask;
        }
        catch (OperationCanceledException)
        {
        }

        teacherCommentRepo.Verify(
            r => r.SetReviewStatusAsync("teacher_comment_1", false, "出现敏感词"),
            Times.Once);
        Assert.That(notificationQueue.TryDequeue(out var notification), Is.True);
        Assert.Multiple(() =>
        {
            Assert.That(notification!.UserId, Is.EqualTo("user_1"));
            Assert.That(notification.Type, Is.EqualTo(NotificationType.Review));
            Assert.That(notification.TargetId, Is.EqualTo("teacher_comment_1"));
            Assert.That(notification.Params, Is.TypeOf<ReviewParams>());
        });
    }

    private sealed class TestableReviewBackgroundService(
        ReviewMessageQueue queue,
        IServiceScopeFactory scopeFactory,
        NotificationMessageQueue notificationQueue,
        IMemoryCache memoryCache,
        IDistributedCache distributedCache,
        ILogger<ReviewBackgroundService> logger)
        : ReviewBackgroundService(queue, scopeFactory, notificationQueue, memoryCache, distributedCache, logger)
    {
        public Task RunAsync(CancellationToken cancellationToken) => ExecuteAsync(cancellationToken);
    }
}
