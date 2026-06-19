import os

MAP = {
    '账号 / 邮箱 / 手机号': 'authAccountPlaceholder',
    '验证码已发送': 'authSendCodeSuccess',
    '6 位验证码': 'authCodePlaceholder',
    '给自己起个名字': 'authNamePlaceholder',
    '邮箱或手机号': 'authAccountHint',
    '密码已重置，请重新登录': 'passwordResetSuccess',
    '注册完成，请使用账号密码登录': 'registerComplete',
    '返回上一步': 'goBack',
    '验证码至少4位': 'codeMinLength',
    '重新获取重置说明': 'regenerateInstructions',
    '新密码': 'passwordNewPlaceholder',
    '当前没有可进入的标签': 'noTagAvailable',
    '进入标签页': 'enterTagPage',
    '选择一个标签，查看该标签下的帖子。': 'chooseTagHint',
    '未命名标签': 'unnamedTag',
    '等第一位同学来发布内容，或者稍后再刷新看看。': 'waitFirstPoster',
    '换个关键词试试，或者清空搜索回到首页。': 'tryDifferentKeyword',
    '正在刷新帖子...': 'refreshingPosts',
    '正在搜索...': 'searching',
    '加载失败': 'loadingFailed',
    '重新加载': 'retry',
    '热榜暂时为空': 'hotListEmpty',
    '等大家再热闹一点，热门帖子就会出现在这里。': 'hotListEmptyDesc',
    '请输入验证码或 Token': 'validatorCodeRequiredToken',
    '请输入新密码': 'validatorPasswordRequired',
    '密码至少 6 位': 'validatorPasswordMinLength',
    '确认新密码': 'authConfirmPassword',
    '请输入有效的邮箱或手机号': 'validatorEmailOrPhoneRequired',
    '密码，至少6位，含大小写字母和数字': 'passwordRequirementHint',
    '重发验证码失败，请稍后重试': 'authSendCodeFailed',
    '验证失败，请稍后重试': 'authVerifyFailed',
    '重置密码失败，请稍后重试': 'authResetFailed',
    '登录成功': 'authLoginSuccess',
    '绑定成功，但刷新资料失败，请稍后下拉刷新': 'commentBindingSuccessRefreshFailed',
}

FILES = [
    'lib/pages/auth/forgot_password_screen.dart',
    'lib/pages/auth/login_screen.dart',
    'lib/pages/auth/register_screen.dart',
    'lib/pages/auth/register_verify_screen.dart',
    'lib/pages/auth/reset_password_screen.dart',
    'lib/pages/auth/oauth_webview_screen.dart',
    'lib/pages/home/home_screen.dart',
    'lib/pages/hot/hot_screen.dart',
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
