import 'package:json_annotation/json_annotation.dart';

part 'teacher_comment.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateTeacherCommentRequest {
  final String teacherName;
  final String courseName;
  final String? comment;
  final int star;

  const CreateTeacherCommentRequest({
    required this.teacherName,
    required this.courseName,
    this.comment,
    required this.star,
  });

  factory CreateTeacherCommentRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTeacherCommentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateTeacherCommentRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class ReviewTeacherCommentRequest {
  final bool isReview;
  final String? reviewNote;

  const ReviewTeacherCommentRequest({required this.isReview, this.reviewNote});

  factory ReviewTeacherCommentRequest.fromJson(Map<String, dynamic> json) =>
      _$ReviewTeacherCommentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewTeacherCommentRequestToJson(this);
}

@JsonSerializable()
class TeacherCommentItem {
  final String key;
  final String teacherName;
  final String courseName;
  final String userId;
  final String? comment;
  final int star;
  final bool isReview;
  final String? aiReason;
  final DateTime? aiReviewedOn;
  final DateTime? reviewedOn;
  final String? reviewedBy;
  final DateTime createdOn;

  const TeacherCommentItem({
    required this.key,
    required this.teacherName,
    required this.courseName,
    required this.userId,
    this.comment,
    required this.star,
    required this.isReview,
    this.aiReason,
    this.aiReviewedOn,
    this.reviewedOn,
    this.reviewedBy,
    required this.createdOn,
  });

  factory TeacherCommentItem.fromJson(Map<String, dynamic> json) =>
      _$TeacherCommentItemFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherCommentItemToJson(this);
}

@JsonSerializable()
class TeacherCommentSummary {
  final String teacherName;
  final int totalCount;
  final double averageStar;
  final List<String> courses;

  const TeacherCommentSummary({
    required this.teacherName,
    required this.totalCount,
    required this.averageStar,
    required this.courses,
  });

  factory TeacherCommentSummary.fromJson(Map<String, dynamic> json) =>
      _$TeacherCommentSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherCommentSummaryToJson(this);
}
