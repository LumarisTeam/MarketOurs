import 'package:json_annotation/json_annotation.dart';

import '../services/error_messages.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final int? code;
  final int? errorCode;
  /// 错误码名称如 "PostNotFound"，方便调试；客户端应基于 errorCode 做程序化判断
  final String? errorName;
  final String? message;
  final String? detail;
  final T? data;
  final String? requestId;
  final String? timestamp;

  ApiResponse({
    this.code,
    this.errorCode,
    this.errorName,
    this.message,
    this.detail,
    this.data,
    this.requestId,
    this.timestamp,
  });

  String get userFacingMessage =>
      errorMessageFromCode(errorCode, fallback: message);

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}
