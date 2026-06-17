using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using MarketOurs.DataAPI.Exceptions;
using MarketOurs.DataAPI.Repos;
using Microsoft.Extensions.Logging;

namespace MarketOurs.DataAPI.Services;

/// <summary>
/// 推送服务接口，处理移动端或浏览器的通知推送
/// </summary>
public interface IPushService
{
    /// <summary>
    /// 发送推送通知
    /// </summary>
    /// <param name="pushToken">目标设备的推送令牌</param>
    /// <param name="title">通知标题</param>
    /// <param name="body">通知正文</param>
    /// <param name="data">附加数据载荷</param>
    Task SendPushNotificationAsync(string pushToken, string title, string body,
        IDictionary<string, string>? data = null);
}

public sealed class FirebasePushException(
    string message,
    bool isTokenInvalid,
    Exception? innerException = null) : Exception(message, innerException)
{
    public bool IsTokenInvalid { get; } = isTokenInvalid;
}

/// <summary>
/// Firebase Cloud Messaging 推送服务
/// </summary>
public class FirebasePushService : IPushService
{
    private const string DefaultChannelId = "marketours_notifications";
    private static readonly object SyncRoot = new();
    private static FirebaseApp? _firebaseApp;

    private readonly FirebaseMessaging _messaging;
    private readonly ILogger<FirebasePushService> _logger;

    public FirebasePushService(
        ILogger<FirebasePushService> logger,
        string serviceAccountPath,
        string? projectId = null)
    {
        _logger = logger;
        _messaging = FirebaseMessaging.GetMessaging(GetOrCreateApp(serviceAccountPath, projectId));
    }

    public async Task SendPushNotificationAsync(string pushToken, string title, string body,
        IDictionary<string, string>? data = null)
    {
        try
        {
            var message = new Message
            {
                Token = pushToken,
                Notification = new Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data?.ToDictionary(kv => kv.Key, kv => kv.Value ?? string.Empty) ?? new Dictionary<string, string>(),
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification
                    {
                        ChannelId = DefaultChannelId
                    }
                }
            };

            await _messaging.SendAsync(message);
        }
        catch (FirebaseMessagingException ex) when (IsInvalidTokenError(ex))
        {
            _logger.LogWarning(ex, "Push token is invalid and should be cleared");
            throw new FirebasePushException("Push token is invalid", true, ex);
        }
        catch (FirebaseMessagingException ex)
        {
            _logger.LogError(ex, "Firebase push send failed");
            throw new FirebasePushException("Push send failed", false, ex);
        }
    }

    private static FirebaseApp GetOrCreateApp(string serviceAccountPath, string? projectId)
    {
        lock (SyncRoot)
        {
            if (_firebaseApp != null)
            {
                return _firebaseApp;
            }

            var options = new AppOptions
            {
                Credential = GoogleCredential.FromFile(serviceAccountPath)
            };

            if (!string.IsNullOrWhiteSpace(projectId))
            {
                options.ProjectId = projectId;
            }

            _firebaseApp = FirebaseApp.Create(options, "MarketOursFirebasePush");
            return _firebaseApp;
        }
    }

    private static bool IsInvalidTokenError(FirebaseMessagingException ex)
    {
        return ex.MessagingErrorCode is MessagingErrorCode.InvalidArgument or MessagingErrorCode.Unregistered;
    }
}

/// <summary>
/// 模拟推送服务，仅记录日志，用于开发和测试环境
/// </summary>
public class MockPushService(ILogger<MockPushService> logger) : IPushService
{
    /// <inheritdoc/>
    public Task SendPushNotificationAsync(string pushToken, string title, string body,
        IDictionary<string, string>? data = null)
    {
        logger.LogInformation("[PUSH MOCK] Sending push to {Token}: {Title} - {Body}", pushToken, title, body);
        if (data != null)
        {
            foreach (var kv in data)
            {
                logger.LogInformation("[PUSH MOCK] Data: {Key}={Value}", kv.Key, kv.Value);
            }
        }

        return Task.CompletedTask;
    }
}
