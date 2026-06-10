namespace MarketOurs.DataAPI.Services;

public static class EmailTemplates
{
    public const string EmailVerification = @"
        <div style='font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 5px;'>
            <h2 style='color: #333;'>验证您的邮箱</h2>
            <p>您好，请使用以下验证码完成 MarketOurs 邮箱验证：</p>
            <div style='background: #f4f4f4; padding: 15px; font-size: 24px; font-weight: bold; text-align: center; letter-spacing: 5px; color: #007bff;'>
                {{ token }}
            </div>
            <p style='color: #666; font-size: 14px; margin-top: 20px;'>
                该验证码 24 小时内有效。如果不是您本人操作，请忽略此邮件。
            </p>
        </div>";

    public const string RegistrationCode = @"
        <div style='font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 5px;'>
            <h2 style='color: #333;'>欢迎加入 MarketOurs</h2>
            <p>感谢您的注册！请使用以下验证码完成账号创建：</p>
            <div style='background: #edf7ed; padding: 15px; font-size: 24px; font-weight: bold; text-align: center; letter-spacing: 5px; color: #2e7d32;'>
                {{ token }}
            </div>
            <p style='color: #666; font-size: 14px; margin-top: 20px;'>
                该验证码 15 分钟内有效。如果您没有注册过 MarketOurs，请忽略此邮件。
            </p>
        </div>";

    public const string LoginCode = @"
        <div style='font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 5px;'>
            <h2 style='color: #333;'>MarketOurs 登录验证码</h2>
            <p>请使用以下验证码登录您的 MarketOurs 账号：</p>
            <div style='background: #eef6ff; padding: 15px; font-size: 24px; font-weight: bold; text-align: center; letter-spacing: 5px; color: #0d6efd;'>
                {{ token }}
            </div>
            <p style='color: #666; font-size: 14px; margin-top: 20px;'>
                该验证码 5 分钟内有效。如果不是您本人登录，请尽快检查账号安全。
            </p>
        </div>";

    public const string ThirdPartyUnbindCode = @"
        <div style='font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 5px;'>
            <h2 style='color: #333;'>解绑第三方账号确认</h2>
            <p>我们收到了解绑 MarketOurs 第三方账号的请求。请使用以下验证码确认本次操作：</p>
            <div style='background: #fff1f0; padding: 15px; font-size: 24px; font-weight: bold; text-align: center; letter-spacing: 5px; color: #cf1322;'>
                {{ token }}
            </div>
            <p style='color: #666; font-size: 14px; margin-top: 20px;'>
                该验证码 15 分钟内有效。如果不是您本人操作，请立即检查账号安全。
            </p>
        </div>";

    public const string PasswordReset = @"
        <div style='font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 5px;'>
            <h2 style='color: #333;'>重置您的密码</h2>
            <p>您好 {{ name }}，我们收到了重置您 MarketOurs 账号密码的请求。</p>
            <p>请使用以下验证码进行重置：</p>
            <div style='background: #fff3cd; padding: 15px; font-size: 24px; font-weight: bold; text-align: center; letter-spacing: 5px; color: #856404;'>
                {{ token }}
            </div>
            <p style='color: #666; font-size: 14px; margin-top: 20px;'>
                该验证码 1 小时内有效。如果您没有申请过重置密码，请务必检查您的账号安全。
            </p>
        </div>";
}
