import os

MAP = {
    '首页': 'tabHome', '热榜': 'tabHot', '通知': 'tabNotifications', '我的': 'tabProfile',
    '登录': 'authLogin', '注册账号': 'authRegister', '找回密码': 'authForgotPassword',
    '重置密码': 'authResetPassword', '修改密码': 'authChangePassword', '退出登录': 'authLogout',
    '清除当前会话': 'authLogoutDesc', '账号': 'authAccount', '密码': 'authPassword',
    '验证码': 'authVerificationCode', '发送验证码': 'authSendCode',
    '账号 / 邮箱 / 手机号': 'authAccountPlaceholder', '请输入密码': 'authPasswordPlaceholder',
    '6 位验证码': 'authCodePlaceholder', '给自己起个名字': 'authNamePlaceholder',
    '邮箱或手机号': 'authAccountHint', '新密码': 'authNewPassword', '当前密码': 'authOldPassword',
    '确认密码': 'authConfirmPassword', '至少6位，含大写、小写字母和数字': 'authPasswordRequirement',
    '验证码登录': 'authCodeLogin', '密码登录': 'authPasswordLogin',
    '已有账号？返回登录': 'authAlreadyHaveAccount', '还没有账号？去注册': 'authNoAccount',
    '忘记密码？': 'authForgotPasswordPrompt', '验证码已发送': 'authSendCodeSuccess',
    '发送验证码失败，请稍后重试': 'authSendCodeFailed',
    '登录成功': 'authLoginSuccess', '登录失败，请稍后重试': 'authLoginFailed',
    '注册成功': 'authRegisterSuccess', '注册失败，请稍后重试': 'authRegisterFailed',
    '重置密码失败，请稍后重试': 'authResetFailed', '修改密码失败，请稍后重试': 'authChangePasswordFailed',
    '验证失败，请稍后重试': 'authVerifyFailed',
    '用户名或密码错误': 'authUsernameOrPasswordWrong', '验证注册': 'authRegisterVerifyTitle',
    '请输入发送到您账号的验证码': 'authRegisterVerifyHint',
    '选择头像': 'authSelectAvatar', '随机生成': 'authRandomAvatar',
    '从相册选择': 'authPickFromGallery', '拍照': 'authTakePhoto', '重新发送': 'authResendCode',
    '资料信息': 'profileInfo', '账户安全': 'profileSecurity', '社交管理': 'profileSocial',
    '第三方绑定': 'profileBindings', '昵称': 'profileNickname', '简介': 'profileBio',
    '邮箱': 'profileEmail', '手机': 'profilePhone', '已通过安全验证': 'profileEmailVerified',
    '尚未进行安全验证': 'profileEmailNotVerified', '去验证': 'profileVerifyEmail',
    '邮箱验证': 'profileVerifyEmailTitle', '输入验证码': 'profileEnterCode',
    '请输入收到的验证码': 'profileEnterCodeHint', '确认验证': 'profileConfirmVerify',
    '还没有登录': 'profileNotLoggedIn',
    '登录后可以查看个人资料、管理安全设置。': 'profileNotLoggedInDesc',
    '去登录': 'profileGoLogin', '编辑资料': 'profileEditProfile',
    '保存修改': 'profileSaveChanges', '保存中...': 'profileSaving',
    '个人资料已更新': 'profileUpdated', '保存失败，请稍后重试': 'profileUpdateFailed',
    '未设置昵称': 'profileNoNickname', '还没有写简介': 'profileNoBio', '未绑定': 'profileNoEmail',
    '点击更换头像': 'profileClickToChangeAvatar',
    '更新当前账号密码': 'profileChangePasswordDesc',
    '粉丝': 'profileFollowers', '关注': 'profileFollowing',
    '屏蔽': 'profileBlock', '已关注': 'profileUnfollow', '已屏蔽': 'profileUnblock',
    '这是你': 'profileThisIsYou', '管理我的资料': 'profileManageMyProfile',
    '加入时间': 'profileJoinDate',
    '这个人很低调，还没有写简介。': 'profileOwnerLowkey',
    '最近发布': 'profileRecentPosts',
    '看看这位同学最近在 光汇 分享了什么。': 'profileRecentPostsSubtitle',
    '还没有公开帖子': 'profileNoPublicPosts', '还没有关注任何人': 'profileNoFollows',
    '已经到底了': 'profileReachedEnd',
    '发布帖子': 'postCreate', '发布中...': 'postCreatePublishing', '发布': 'postCreatePublish',
    '正在发布': 'postCreatePublishing', '立即发布': 'postCreatePublish',
    '帖子标题': 'postCreateTitle', '请输入标题': 'postCreateTitleEmpty',
    '请输入内容': 'postCreateContentEmpty',
    '图片': 'postCreateImages', '添加图片': 'postCreateAddImages',
    '还没选择图片': 'postCreateNoImages', '标签': 'postCreateTag',
    '无标签': 'postCreateNoTag', '帖子已发布': 'postCreated',
    '帖子创建失败': 'postCreateFailed', '图片上传失败': 'postImagesUploadFailed',
    '分享此刻的新鲜事...': 'postCreateContent',
    '详情': 'postDetail', '帖子详情': 'postDetailTitle', '帖子不存在': 'postNotFound',
    '帖子已删除': 'postDeleted', '暂无评论': 'postNoComments',
    '写下你的评论...': 'postWriteComment', '评论已发布': 'postCommentSent',
    '评论发送失败': 'postCommentFailed', '来自光汇的帖子': 'postShareTitle',
    '加载更多': 'postLoadMore', '加载中...': 'postLoading', '用户不存在': 'postUserNotFound',
    '请先登录': 'postPleaseLogin', '图片已保存到系统相册': 'postImageSaveSuccess',
    '图片保存失败': 'postImageSaveFailed',
    '这个标签下还没有帖子': 'postTagEmpty',
    '搜索帖子、话题或用户': 'homeSearchPlaceholder', '还没有帖子': 'homeEmpty',
    '还没有热门帖子': 'homeHotEmpty',
    '暂时没有通知': 'notificationEmpty', '推送设置': 'notificationPushSettings',
    '邮件通知': 'notificationEmail', '评论回复推送': 'notificationCommentPush',
    '每日热榜推送': 'notificationHotListPush',
    '当收到新回复或系统通知时发送邮件': 'notificationEmailDesc',
    '当有人回复您的贴子或评论时推送': 'notificationCommentPushDesc',
    '每天早晨接收校园最热贴子精选': 'notificationHotListPushDesc',
    '保存设置': 'notificationSaveSettings', '保存成功': 'notificationSaved',
    '保存失败': 'notificationSaveFailed', '保存中': 'notificationSaving',
    '点赞': 'likePost', '点踩': 'dislikePost',
    '取消': 'cancel', '确定': 'ok', '确认': 'confirm', '重试': 'retry',
    '重新加载': 'reload', '保存': 'save', '删除': 'delete', '编辑': 'edit',
    '搜索': 'search', '提交': 'submit', '返回': 'back', '关闭': 'close', '完成': 'done',
    '是': 'yes', '否': 'no',
    '外观偏好': 'themeMode', '点击切换显示模式': 'themeHint',
    '选择外观模式': 'appearanceModeTitle',
    '上传中...': 'postUploading',
    '操作失败，请稍后重试': 'errorGeneral', '连接服务器超时': 'errorNetworkTimeout',
    '网络连接失败': 'errorNetworkFailed', '请求已取消': 'errorRequestCancelled',
    '文件上传失败': 'errorFileUploadFailed', '头像上传失败': 'errorAvatarUploadFailed',
    '服务器错误，请稍后重试': 'errorServerError',
    '文件未找到': 'errorFileNotFound',
    '隐私政策': 'privacyPolicy', '服务条款': 'termsOfService',
    '语言': 'settingsLanguage', '语言设置': 'settingsLanguageTitle', '设置': 'settingsTitle',
    '最新': 'postCommentSortNewest', '最早': 'postCommentSortOldest',
    '最热': 'postCommentSortHot',
    '再按一次退出光汇': 'appTitle',
}

BASE_DIR = r'E:\Programming\MarketOurs\app\mobile_app\lib'
IGNORE_DIRS = {'l10n', 'models', 'services'}  # skip ARB, generated code, and API service files

sorted_keys = sorted(MAP.keys(), key=len, reverse=True)
file_count = 0
total_changes = 0

for root, dirs, files in os.walk(BASE_DIR):
    dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
    for fname in files:
        if not fname.endswith('.dart'):
            continue
        filepath = os.path.join(root, fname)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content
        changes = 0
        for cn_str in sorted_keys:
            key = MAP[cn_str]
            old_single = f"'{cn_str}'"
            new_val = f"AppLocalizations.of(context)!.{key}"
            if old_single in content:
                content = content.replace(old_single, new_val)
                changes += 1
            old_double = f'"{cn_str}"'
            if old_double in content:
                content = content.replace(old_double, new_val)
                changes += 1

        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            relpath = os.path.relpath(filepath, BASE_DIR)
            print(f"  {relpath}: {changes} strings")
            file_count += 1
            total_changes += changes

print(f"\nDone: {file_count} files, {total_changes} string replacements")
