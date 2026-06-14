class DtoLimits {
  const DtoLimits._();

  static const postTitleMax = 128;
  static const postContentMax = 1024;
  static const commentContentMax = 512;
  static const userAccountMax = 128;
  static const userPasswordMin = 6;
  static const userPasswordMax = 128;
  static const userNameMax = 128;
  static const userAvatarMax = 128;
  static const userEmailMax = 128;
  static const userPhoneMax = 32;
  static const userInfoMax = 1024;
}

String? requiredMaxValidator(
  String? value, {
  required String emptyMessage,
  required int max,
  required String maxMessage,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return emptyMessage;
  if (text.length > max) return maxMessage;
  return null;
}

String? optionalMaxValidator(
  String? value, {
  required int max,
  required String maxMessage,
}) {
  final text = value?.trim() ?? '';
  if (text.length > max) return maxMessage;
  return null;
}

String? passwordLengthValidator(
  String? value, {
  required String emptyMessage,
  required String minMessage,
  required String maxMessage,
}) {
  final text = value ?? '';
  if (text.isEmpty) return emptyMessage;
  if (text.length < DtoLimits.userPasswordMin) return minMessage;
  if (text.length > DtoLimits.userPasswordMax) return maxMessage;
  return null;
}
