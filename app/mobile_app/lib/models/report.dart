enum ReportTargetType { post, comment, user }
enum ReportReason { spamOrAdvertising, fraudOrTransactionRisk, sexualOrInappropriate, hateOrHarassment, other }

class CreateReportRequest {
  const CreateReportRequest({required this.targetType, required this.targetId, required this.reason, this.description});
  final ReportTargetType targetType;
  final String targetId;
  final ReportReason reason;
  final String? description;
  Map<String, dynamic> toJson() => {'targetType': targetType.index, 'targetId': targetId, 'reason': reason.index, 'description': description};
}
