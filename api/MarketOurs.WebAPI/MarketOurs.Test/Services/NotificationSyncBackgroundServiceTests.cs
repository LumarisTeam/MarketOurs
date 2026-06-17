using MarketOurs.Data.DataModels;
using MarketOurs.Data.DTOs;
using MarketOurs.DataAPI.Repos;
using MarketOurs.DataAPI.Services;
using MarketOurs.DataAPI.Services.Background;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Moq;

namespace MarketOurs.Test.Services;

[TestFixture]
public class NotificationSyncBackgroundServiceTests
{
    [Test]
    public async Task ExecuteAsync_WhenCommentPushEnabled_ShouldSendPush()
    {
        var fixture = CreateFixture(
            user: new UserModel
            {
                Id = "user_1",
                PushToken = "token_1",
                PushSettings = "{\"enableEmailNotifications\":false,\"enableHotListPush\":true,\"enableCommentReplyPush\":true}"
            });

        fixture.Queue.Enqueue(new NotificationMessage
        {
            UserId = "user_1",
            Title = "标题",
            Content = "内容",
            Type = NotificationType.CommentReply,
            TargetId = "post_1"
        });

        await fixture.RunUntilProcessedAsync();

        fixture.PushService.Verify(x => x.SendPushNotificationAsync(
            "token_1",
            "标题",
            "内容",
            It.Is<Dictionary<string, string>>(data =>
                data["type"] == NotificationType.CommentReply.ToString() &&
                data["targetId"] == "post_1")),
            Times.Once);
    }

    [Test]
    public async Task ExecuteAsync_WhenCommentPushDisabled_ShouldNotSendPush()
    {
        var fixture = CreateFixture(
            user: new UserModel
            {
                Id = "user_1",
                PushToken = "token_1",
                PushSettings = "{\"enableEmailNotifications\":false,\"enableHotListPush\":true,\"enableCommentReplyPush\":false}"
            });

        fixture.Queue.Enqueue(new NotificationMessage
        {
            UserId = "user_1",
            Title = "标题",
            Content = "内容",
            Type = NotificationType.CommentReply,
            TargetId = "post_1"
        });

        await fixture.RunUntilProcessedAsync();

        fixture.PushService.Verify(x => x.SendPushNotificationAsync(
            It.IsAny<string>(),
            It.IsAny<string>(),
            It.IsAny<string>(),
            It.IsAny<IDictionary<string, string>>()),
            Times.Never);
    }

    [Test]
    public async Task ExecuteAsync_WhenSystemNotification_ShouldSendPushEvenIfFeatureFlagsDisabled()
    {
        var fixture = CreateFixture(
            user: new UserModel
            {
                Id = "user_1",
                PushToken = "token_1",
                PushSettings = "{\"enableEmailNotifications\":false,\"enableHotListPush\":false,\"enableCommentReplyPush\":false}"
            });

        fixture.Queue.Enqueue(new NotificationMessage
        {
            UserId = "user_1",
            Title = "系统标题",
            Content = "系统内容",
            Type = NotificationType.System
        });

        await fixture.RunUntilProcessedAsync();

        fixture.PushService.Verify(x => x.SendPushNotificationAsync(
            "token_1",
            "系统标题",
            "系统内容",
            It.IsAny<IDictionary<string, string>>()),
            Times.Once);
    }

    [Test]
    public async Task ExecuteAsync_WhenPushTokenInvalid_ShouldClearUserToken()
    {
        var user = new UserModel
        {
            Id = "user_1",
            PushToken = "token_1",
            PushSettings = "{\"enableEmailNotifications\":false,\"enableHotListPush\":true,\"enableCommentReplyPush\":true}"
        };
        var fixture = CreateFixture(user: user);
        fixture.PushService
            .Setup(x => x.SendPushNotificationAsync(
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<string>(),
                It.IsAny<IDictionary<string, string>>()))
            .ThrowsAsync(new FirebasePushException("invalid token", true));

        fixture.Queue.Enqueue(new NotificationMessage
        {
            UserId = "user_1",
            Title = "标题",
            Content = "内容",
            Type = NotificationType.CommentReply,
            TargetId = "post_1"
        });

        await fixture.RunUntilProcessedAsync();

        fixture.UserRepo.Verify(x => x.UpdateAsync(It.Is<UserModel>(u =>
            u.Id == "user_1" &&
            u.PushToken == string.Empty)), Times.Once);
    }

    private static TestFixtureContext CreateFixture(UserModel user)
    {
        var queue = new NotificationMessageQueue();
        var notificationService = new Mock<INotificationService>();
        var userRepo = new Mock<IUserRepo>();
        var emailService = new Mock<IEmailService>();
        var pushService = new Mock<IPushService>();
        var logger = new Mock<ILogger<NotificationSyncBackgroundService>>();

        notificationService.Setup(x => x.CreateNotificationAsync(It.IsAny<NotificationModel>()))
            .Returns(Task.CompletedTask);
        notificationService.Setup(x => x.GetPushSettingsAsync(user.Id))
            .ReturnsAsync(new MarketOurs.Data.DTOs.PushSettingsDto
            {
                EnableEmailNotifications = user.PushSettings?.Contains("\"enableEmailNotifications\":true") == true,
                EnableHotListPush = user.PushSettings?.Contains("\"enableHotListPush\":true") == true,
                EnableCommentReplyPush = user.PushSettings?.Contains("\"enableCommentReplyPush\":true") == true
            });
        userRepo.Setup(x => x.GetByIdAsync(user.Id)).ReturnsAsync(user);
        userRepo.Setup(x => x.UpdateAsync(It.IsAny<UserModel>())).Returns(Task.CompletedTask);

        var scopedProvider = new Mock<IServiceProvider>();
        scopedProvider.Setup(x => x.GetService(typeof(INotificationService))).Returns(notificationService.Object);
        scopedProvider.Setup(x => x.GetService(typeof(IUserRepo))).Returns(userRepo.Object);
        scopedProvider.Setup(x => x.GetService(typeof(IEmailService))).Returns(emailService.Object);
        scopedProvider.Setup(x => x.GetService(typeof(IPushService))).Returns(pushService.Object);

        var scope = new Mock<IServiceScope>();
        scope.SetupGet(x => x.ServiceProvider).Returns(scopedProvider.Object);

        var scopeFactory = new Mock<IServiceScopeFactory>();
        scopeFactory.Setup(x => x.CreateScope()).Returns(scope.Object);

        var service = new TestableNotificationSyncBackgroundService(
            queue,
            scopeFactory.Object,
            logger.Object);

        return new TestFixtureContext(
            service,
            queue,
            userRepo,
            pushService,
            notificationService);
    }

    private sealed record TestFixtureContext(
        TestableNotificationSyncBackgroundService Service,
        NotificationMessageQueue Queue,
        Mock<IUserRepo> UserRepo,
        Mock<IPushService> PushService,
        Mock<INotificationService> NotificationService)
    {
        public async Task RunUntilProcessedAsync()
        {
            using var cts = new CancellationTokenSource();
            var runTask = Service.RunAsync(cts.Token);
            await Task.Delay(300);
            cts.Cancel();

            try
            {
                await runTask;
            }
            catch (OperationCanceledException)
            {
            }
        }
    }

    private sealed class TestableNotificationSyncBackgroundService(
        NotificationMessageQueue queue,
        IServiceScopeFactory scopeFactory,
        ILogger<NotificationSyncBackgroundService> logger)
        : NotificationSyncBackgroundService(queue, scopeFactory, logger)
    {
        public Task RunAsync(CancellationToken cancellationToken) => ExecuteAsync(cancellationToken);
    }
}
