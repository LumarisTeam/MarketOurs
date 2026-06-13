import 'package:flutter/cupertino.dart';

import 'legal_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScreen(
      title: '用户协议',
      lastUpdated: '2026年6月13日',
      sections: [
        LegalSection(title: '一、总则', children: [
          legalParagraph(
            '1.1 光汇 是一个面向校园师生的信息交流与二手交易平台，旨在为校园社区提供便捷、安全的信息发布与交流服务。',
          ),
          legalParagraph(
            '1.2 本协议适用于所有注册用户及未注册但浏览本平台内容的访问者（以下统称"用户"）。',
          ),
          legalParagraph(
            '1.3 本平台有权根据需要不时修订本协议，修订后的协议将在平台公示。如您不同意修订内容，应立即停止使用本平台服务；继续使用则视为接受修订后的协议。',
          ),
        ]),
        LegalSection(title: '二、账号注册与管理', children: [
          legalParagraph(
            '2.1 您承诺在注册时提供真实、准确、完整的个人信息，并在信息变更时及时更新。',
          ),
          legalParagraph(
            '2.2 您应妥善保管账号及密码，对以您账号进行的所有活动承担法律责任。如发现账号被盗用或存在安全漏洞，请立即通知本平台。',
          ),
          legalParagraph(
            '2.3 每个用户仅允许注册一个账号。禁止冒用他人身份信息注册，禁止转让、出借或售卖账号。',
          ),
          legalParagraph(
            '2.4 本平台有权对长期未使用的账号进行注销处理，但会提前通过合理方式通知用户。',
          ),
          legalParagraph(
            '2.5 您在注册时可以选择绑定第三方平台账号（如 GitHub、Google、微信等）以简化登录流程，您应对所绑定的第三方账号的合法性负责。',
          ),
        ]),
        LegalSection(title: '三、用户行为规范', children: [
          legalParagraph(
            '3.1 您在使用本平台时应遵守中华人民共和国法律法规，不得利用本平台从事违法违规行为，包括但不限于：危害国家安全、破坏民族团结、散布谣言、侮辱诽谤他人、发布虚假诈骗信息、传播淫秽色情内容等法律禁止的行为。',
          ),
          legalParagraph(
            '3.2 禁止在平台内实施干扰正常运营的行为：利用技术手段批量注册账号或恶意刷量；上传或传播病毒、木马等恶意程序；对平台服务器进行网络攻击或非法入侵；未经授权抓取或复制平台数据。',
          ),
          legalParagraph(
            '3.3 对于违反上述规定的用户，本平台有权采取包括但不限于警告、限制功能、暂停服务、永久封禁账号等措施，并保留追究法律责任的权利。',
          ),
        ]),
        LegalSection(title: '四、内容发布规范', children: [
          legalParagraph(
            '4.1 用户在本平台发布的文章、评论、图片等内容应确保：内容真实、合法、不侵犯他人合法权益；发布二手交易信息时，应如实描述物品状况，不得发布假冒伪劣商品；图片内容应清晰且与交易物品或文章主题直接相关。',
          ),
          legalParagraph(
            '4.2 用户在平台发布的内容仅代表用户个人观点，不代表本平台立场。',
          ),
          legalParagraph(
            '4.3 本平台有权对违反本协议的用户内容进行删除或屏蔽，无需事先通知。',
          ),
          legalParagraph(
            '4.4 您授予本平台一项全球范围内、免费、非排他性、可再许可的使用权，以便本平台在运营过程中对您发布的内容进行存储、展示和传播。',
          ),
        ]),
        LegalSection(title: '五、知识产权', children: [
          legalParagraph(
            '5.1 本平台的名称、标识、界面设计、源代码、数据库等知识产权归本平台运营方所有。',
          ),
          legalParagraph(
            '5.2 用户保留对其发布内容的著作权及其他相关权利。但用户同意本平台有权在平台范围内使用、展示和传播该等内容。',
          ),
          legalParagraph(
            '5.3 如用户发布的内容侵犯了第三方知识产权，该用户应自行承担全部法律责任。',
          ),
        ]),
        LegalSection(title: '六、免责声明', children: [
          legalParagraph(
            '6.1 本平台按"现状"提供服务，对于因网络故障、系统维护、第三方攻击等不可抗力因素导致的服务中断，本平台不承担责任，但将尽力在合理时间内恢复服务。',
          ),
          legalParagraph(
            '6.2 二手交易风险：本平台仅提供信息发布与交流的场所，不对交易双方之间的交易行为承担任何担保责任。用户应自行评估交易风险，谨慎进行线下交易。',
          ),
          legalParagraph(
            '6.3 用户之间的纠纷应由双方自行协商解决，本平台不承担调解或赔偿责任。',
          ),
          legalParagraph(
            '6.4 本平台不保证用户发布的全部信息的准确性、完整性或可靠性。',
          ),
        ]),
        LegalSection(title: '七、服务终止', children: [
          legalParagraph(
            '7.1 用户可随时通过注销账号的方式终止使用本平台服务。',
          ),
          legalParagraph(
            '7.2 发生以下情形，本平台有权终止向您提供服务：违反本协议或相关法律法规的；提供虚假注册信息的；您行为可能给本平台或其他用户造成损害的；根据法律法规或有权机关的要求。',
          ),
          legalParagraph(
            '7.3 账号注销后，本平台将按照隐私条款的规定处理您的个人信息。',
          ),
        ]),
        LegalSection(title: '八、争议解决', children: [
          legalParagraph(
            '8.1 本协议的订立、执行和解释及争议的解决均适用中华人民共和国法律。',
          ),
          legalParagraph(
            '8.2 因本协议引起的或与本协议有关的争议，双方应友好协商解决；协商不成的，任何一方可将争议提交至本平台运营方所在地有管辖权的人民法院诉讼解决。',
          ),
        ]),
        LegalSection(title: '九、通知与更新', children: [
          legalParagraph(
            '9.1 本平台将通过站内通知、邮件或平台公告等方式向用户发送协议更新、服务变更等重要通知。',
          ),
          legalParagraph(
            '9.2 本协议的任何变更将在平台公布后合理期限后生效。您应定期查看本协议以了解最新条款。',
          ),
        ]),
        LegalSection(title: '十、联系方式', children: [
          legalParagraph(
            '如您对本协议有任何疑问、意见或建议，请通过以下方式联系我们：',
          ),
          legalBullet('电子邮箱：support@lumalis.com'),
          legalBullet('站内反馈：登录后通过"个人中心 → 意见反馈"提交'),
        ]),
      ],
    );
  }
}
