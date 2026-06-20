import os

MAP = {
    '校园集市': 'appSlogan',
    '验证码已发送，请继续重置密码': 'verifyCodeSentContinue',
    '发送验证码失败，请稍后重试': 'authSendCodeFailed',
    '请输入账号': 'validatorAccountRequired',
    '请输入密码': 'validatorPasswordRequired',
    '请输入验证码': 'validatorCodeRequired',
    '请输入显示名称': 'validatorNameRequired',
    '显示名称': 'displayName',
    '登录成功': 'authLoginSuccess',
    '登录失败，请检查账号和密码': 'loginFailedCheckAccount',
    '登录失败，请检查验证码': 'loginFailedCheckCode',
    '头像上传失败': 'errorAvatarUploadFailed',
    '注册失败，请稍后重试': 'authRegisterFailed',
    '关注与屏蔽': 'profileFollowBlock',
    '管理关注的用户和屏蔽列表': 'profileFollowBlockDesc',
    '关于': 'profileAbout',
    '用户协议': 'profileTerms',
    '查看平台使用条款': 'profileTermsDesc',
    '隐私条款': 'profilePrivacy',
    '了解我们如何保护你的信息': 'profilePrivacyDesc',
    '显示设置': 'profileDisplaySettings',
    '管理 Github、Google 等平台关联': 'profileManageSocialDesc',
    '两次输入的密码不一致': 'validatorConfirmPasswordMismatch',
    '我的': 'profileNavTitle',
    '用户主页': 'profilePublicProfile',
    '未知': 'profileUnknownDate',
    '邮箱验证成功': 'profileEmailVerifySuccess',
    '提交中...': 'profileSubmitting',
    '正在上传图片': 'uploadingImages',
    '取消': 'cancel',
    '确认': 'confirm',
    '确定': 'ok',
    '保存': 'save',
    '关闭': 'close',
    '重新打开': 'oauthWebViewReopen',
    '正在打开': 'oauthWebViewOpening',
    '绑定成功': 'commentBindingSuccess',
    '登录失败，缺少令牌': 'oauthWebViewLoginFailed',
    '登录失败，请稍后重试': 'authLoginFailed',
}

FILES = [
    'lib/pages/auth/auth_loading_screen.dart',
    'lib/pages/auth/forgot_password_screen.dart',
    'lib/pages/auth/login_screen.dart',
    'lib/pages/auth/register_screen.dart',
    'lib/pages/auth/register_verify_screen.dart',
    'lib/pages/auth/reset_password_screen.dart',
    'lib/pages/auth/oauth_webview_screen.dart',
    'lib/pages/profile/profile_screen.dart',
    'lib/pages/profile/public_profile_screen.dart',
    'lib/components/post_editor_form.dart',
    'lib/components/post_tag_selector.dart',
    'lib/pages/post/post_detail_screen.dart',
    'lib/pages/post/create_post_screen.dart',
]

BASE = r'E:\Programming\MarketOurs\app\mobile_app'
sorted_keys = sorted(MAP.keys(), key=len, reverse=True)

for fname in FILES:
    fpath = os.path.join(BASE, fname)
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    changes = 0
    for cn_str in sorted_keys:
        key = MAP[cn_str]
        old = f"'{cn_str}'"
        new = f"AppLocalizations.of(context).{key}"
        if old in content:
            content = content.replace(old, new)
            changes += 1

    if content != original:
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  {fname}: {changes} strings")

print("Done")
