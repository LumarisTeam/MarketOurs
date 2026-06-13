import 'package:flutter/cupertino.dart';

import 'legal_screen.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScreen(
      title: '隐私条款',
      lastUpdated: '2026年6月13日',
      sections: [
        LegalSection(title: '一、信息收集', children: [
          legalParagraph('您主动提供的信息：'),
          legalBullet('注册信息：账号标识（邮箱或手机号）、密码和显示名称。'),
          legalBullet('个人资料信息：您可以选择性提供头像、个人简介等。'),
          legalBullet('发布内容：您在平台发布的文章、评论、图片等。'),
          legalBullet('反馈信息：您向平台提交的意见反馈、投诉举报等。'),
          legalParagraph('自动收集的信息：'),
          legalBullet('设备信息：包括设备型号、操作系统版本、浏览器类型等。'),
          legalBullet('日志信息：包括IP地址、访问时间、访问页面、操作行为等。'),
          legalBullet('Cookie及类似技术：用于维持登录状态、记住用户偏好、分析平台访问情况等。'),
          legalParagraph(
            '第三方认证信息：当您使用第三方平台（GitHub、Google、微信）登录时，我们会根据授权获取您的基本信息（如昵称、头像、OpenID等），具体以第三方授权页面为准。',
          ),
        ]),
        LegalSection(title: '二、信息使用', children: [
          legalParagraph('2.1 我们收集您的个人信息主要用于以下目的：'),
          legalBullet('提供、维护和改进平台服务；'),
          legalBullet('完成账号注册、登录、身份验证等必要功能；'),
          legalBullet('保障平台和用户的网络安全；'),
          legalBullet('向您发送服务相关的通知（如安全提醒、协议更新等）；'),
          legalBullet('分析和统计平台使用情况，优化用户体验；'),
          legalBullet('防范和调查欺诈、滥用等违规行为；'),
          legalBullet('满足法律法规的要求。'),
          legalParagraph(
            '2.2 我们不会使用您的个人信息进行自动化决策，也不会利用个人信息进行用户画像以影响您的权益。',
          ),
          legalParagraph(
            '2.3 如我们需要将您的信息用于本条款未载明的其他目的，我们将事先征得您的同意。',
          ),
        ]),
        LegalSection(title: '三、信息共享与披露', children: [
          legalParagraph('3.1 我们不会将您的个人信息出售给任何第三方。'),
          legalParagraph('3.2 在以下情形下，我们可能会共享或披露您的信息：'),
          legalBullet('获得您的明确同意；'),
          legalBullet(
            '与第三方服务提供商共享：为提供平台服务（如邮件发送、云存储、CDN加速），我们与可信赖的第三方服务商共享必要信息，并会要求其遵守严格的数据保护义务；',
          ),
          legalBullet('法律要求：根据法律法规、法院命令或政府机关的要求进行披露；'),
          legalBullet(
            '保护权益：为保护我们、用户或公众的合法权益免遭损害时进行合理披露。',
          ),
          legalParagraph(
            '3.3 您发布的公开信息（如昵称、头像、文章和评论）将面向所有平台用户可见。请谨慎发布包含个人敏感信息的公开内容。',
          ),
        ]),
        LegalSection(title: '四、数据安全', children: [
          legalParagraph(
            '4.1 我们采用业界通行的安全技术和组织措施保护您的个人信息：数据加密传输（TLS/SSL）；密码加密存储（不可逆哈希算法）；访问权限控制和审计日志；定期安全评估和漏洞扫描；数据备份和容灾措施。',
          ),
          legalParagraph(
            '4.2 尽管我们采取了合理的安全措施，但请理解没有任何互联网传输或电子存储方法是100%安全的。',
          ),
          legalParagraph(
            '4.3 如发生个人信息安全事件，我们将按照法律法规的要求及时告知您，并向有关主管部门报告。',
          ),
        ]),
        LegalSection(title: '五、Cookie 与类似技术', children: [
          legalParagraph(
            '5.1 本平台使用 Cookie 和类似的本地存储技术来提升您的使用体验：',
          ),
          legalBullet('会话Cookie：维持您的登录状态，关闭浏览器后自动失效；'),
          legalBullet('偏好Cookie：记住您的语言偏好和主题设置；'),
          legalBullet('分析Cookie：帮助我们了解平台的访问情况，持续改进服务。'),
          legalParagraph(
            '5.2 您可以通过浏览器设置拒绝或清除 Cookie，但这可能导致部分功能无法正常使用。',
          ),
        ]),
        LegalSection(title: '六、您的权利', children: [
          legalParagraph('6.1 您享有以下权利：'),
          legalBullet('查阅权：您有权查阅我们持有的您的个人信息；'),
          legalBullet('更正权：您有权更正不准确的个人信息，可在"个人中心"自行修改；'),
          legalBullet('删除权：您有权请求删除您的个人信息（账号注销）；'),
          legalBullet('数据可携权：在法律规定条件下，您有权获取个人信息的副本；'),
          legalBullet(
            '撤回同意：您可以随时撤回同意，但不影响撤回前已进行的处理的合法性。',
          ),
          legalParagraph(
            '6.2 如需行使上述权利，请通过本条款底部提供的联系方式联系我们，我们将在15个工作日内回复。',
          ),
        ]),
        LegalSection(title: '七、数据存储与跨境传输', children: [
          legalParagraph(
            '7.1 您的个人信息存储于中华人民共和国境内的服务器上。',
          ),
          legalParagraph(
            '7.2 我们仅在实现本条款所述目的所必需的最短期限内保留您的个人信息，除非法律法规有更长的保留要求。',
          ),
          legalParagraph(
            '7.3 账号注销后，我们将对您的个人信息进行匿名化处理或安全删除。',
          ),
        ]),
        LegalSection(title: '八、未成年人保护', children: [
          legalParagraph(
            '8.1 本平台主要面向高等院校的在校师生，不面向未满14周岁的儿童提供服务。',
          ),
          legalParagraph(
            '8.2 如果您是未满18周岁的未成年人，请在法定监护人的陪同下阅读本隐私条款，并在征得监护人同意后使用本平台。',
          ),
          legalParagraph(
            '8.3 如我们发现未成年人未经监护人同意提供了个人信息，我们将及时删除相关数据。',
          ),
        ]),
        LegalSection(title: '九、第三方服务', children: [
          legalParagraph(
            '9.1 本平台可能包含指向第三方网站或服务的链接，这些第三方服务独立运营，其隐私做法与本平台无关。',
          ),
          legalParagraph(
            '9.2 本平台涉及的第三方服务包括：GitHub OAuth、Google OAuth、微信开放平台（第三方登录）；邮件服务（发送验证码和系统通知）；云端存储服务（图片等内容存储）。',
          ),
        ]),
        LegalSection(title: '十、隐私条款的更新', children: [
          legalParagraph(
            '10.1 我们可能会不定时更新本隐私条款，重大变更将通过站内通知、邮件或平台公告等方式告知您。',
          ),
          legalParagraph(
            '10.2 我们建议您定期查阅本隐私条款，以了解最新的隐私保护信息。',
          ),
        ]),
        LegalSection(title: '十一、联系方式', children: [
          legalParagraph(
            '如您对本隐私条款有任何疑问，或希望行使您的数据权利，请通过以下方式联系我们：',
          ),
          legalBullet('电子邮箱：privacy@lumalis.com'),
          legalBullet('站内反馈：登录后通过"个人中心 → 意见反馈"提交'),
        ]),
      ],
    );
  }
}
