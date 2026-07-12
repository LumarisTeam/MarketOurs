import 'package:flutter/cupertino.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../services/error_messages.dart';
import '../ui/app_feedback.dart';

Future<void> showReportSheet(BuildContext context, {required ReportTargetType targetType, required String targetId}) async {
  ReportReason reason = ReportReason.spamOrAdvertising;
  final description = TextEditingController();
  final labels = <ReportReason, String>{
    ReportReason.spamOrAdvertising: '垃圾广告', ReportReason.fraudOrTransactionRisk: '欺诈/交易风险',
    ReportReason.sexualOrInappropriate: '色情低俗', ReportReason.hateOrHarassment: '仇恨/骚扰', ReportReason.other: '其他',
  };
  await showCupertinoModalPopup<void>(context: context, builder: (sheetContext) => StatefulBuilder(builder: (context, setState) => CupertinoActionSheet(
    title: const Text('举报'), message: const Text('请选择举报理由，可补充说明。'),
    actions: [
      for (final item in ReportReason.values) CupertinoActionSheetAction(onPressed: () => setState(() => reason = item), child: Text('${reason == item ? '✓ ' : ''}${labels[item]}')),
      CupertinoActionSheetAction(onPressed: () async {
        if (reason == ReportReason.other && description.text.trim().isEmpty) { await AppFeedback.showError(context, message: '请选择“其他”时请填写说明'); return; }
        try {
          await ReportService().createReport(CreateReportRequest(targetType: targetType, targetId: targetId, reason: reason, description: description.text.trim().isEmpty ? null : description.text.trim()));
          if (context.mounted) { Navigator.of(context).pop(); await AppFeedback.showSuccess(context, message: '举报已提交'); }
        } catch (error) { if (context.mounted) await AppFeedback.showError(context, message: extractErrorFromException(error)); }
      }, child: const Text('提交举报')),
    ],
    cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
  )));
  description.dispose();
}
