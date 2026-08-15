// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTeacherCommentRequest _$CreateTeacherCommentRequestFromJson(
  Map<String, dynamic> json,
) => CreateTeacherCommentRequest(
  teacherName: json['teacherName'] as String,
  courseName: json['courseName'] as String,
  comment: json['comment'] as String?,
  star: (json['star'] as num).toInt(),
);

Map<String, dynamic> _$CreateTeacherCommentRequestToJson(
  CreateTeacherCommentRequest instance,
) => <String, dynamic>{
  'teacherName': instance.teacherName,
  'courseName': instance.courseName,
  'comment': ?instance.comment,
  'star': instance.star,
};

UpdateTeacherCommentRequest _$UpdateTeacherCommentRequestFromJson(
  Map<String, dynamic> json,
) => UpdateTeacherCommentRequest(
  teacherName: json['teacherName'] as String,
  courseName: json['courseName'] as String,
  comment: json['comment'] as String?,
  star: (json['star'] as num).toInt(),
);

Map<String, dynamic> _$UpdateTeacherCommentRequestToJson(
  UpdateTeacherCommentRequest instance,
) => <String, dynamic>{
  'teacherName': instance.teacherName,
  'courseName': instance.courseName,
  'comment': ?instance.comment,
  'star': instance.star,
};

ReviewTeacherCommentRequest _$ReviewTeacherCommentRequestFromJson(
  Map<String, dynamic> json,
) => ReviewTeacherCommentRequest(
  isReview: json['isReview'] as bool,
  reviewNote: json['reviewNote'] as String?,
);

Map<String, dynamic> _$ReviewTeacherCommentRequestToJson(
  ReviewTeacherCommentRequest instance,
) => <String, dynamic>{
  'isReview': instance.isReview,
  'reviewNote': ?instance.reviewNote,
};

TeacherCommentItem _$TeacherCommentItemFromJson(Map<String, dynamic> json) =>
    TeacherCommentItem(
      key: json['key'] as String,
      teacherName: json['teacherName'] as String,
      courseName: json['courseName'] as String,
      userId: json['userId'] as String,
      author: json['author'] == null
          ? null
          : UserSimpleDto.fromJson(json['author'] as Map<String, dynamic>),
      comment: json['comment'] as String?,
      star: (json['star'] as num).toInt(),
      isReview: json['isReview'] as bool,
      aiReason: json['aiReason'] as String?,
      aiReviewedOn: json['aiReviewedOn'] == null
          ? null
          : DateTime.parse(json['aiReviewedOn'] as String),
      reviewedOn: json['reviewedOn'] == null
          ? null
          : DateTime.parse(json['reviewedOn'] as String),
      reviewedBy: json['reviewedBy'] as String?,
      createdOn: DateTime.parse(json['createdOn'] as String),
    );

Map<String, dynamic> _$TeacherCommentItemToJson(TeacherCommentItem instance) =>
    <String, dynamic>{
      'key': instance.key,
      'teacherName': instance.teacherName,
      'courseName': instance.courseName,
      'userId': instance.userId,
      'author': instance.author,
      'comment': instance.comment,
      'star': instance.star,
      'isReview': instance.isReview,
      'aiReason': instance.aiReason,
      'aiReviewedOn': instance.aiReviewedOn?.toIso8601String(),
      'reviewedOn': instance.reviewedOn?.toIso8601String(),
      'reviewedBy': instance.reviewedBy,
      'createdOn': instance.createdOn.toIso8601String(),
    };

TeacherCommentSummary _$TeacherCommentSummaryFromJson(
  Map<String, dynamic> json,
) => TeacherCommentSummary(
  teacherName: json['teacherName'] as String,
  totalCount: (json['totalCount'] as num).toInt(),
  averageStar: (json['averageStar'] as num).toDouble(),
  courses: (json['courses'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$TeacherCommentSummaryToJson(
  TeacherCommentSummary instance,
) => <String, dynamic>{
  'teacherName': instance.teacherName,
  'totalCount': instance.totalCount,
  'averageStar': instance.averageStar,
  'courses': instance.courses,
};
