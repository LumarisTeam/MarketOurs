import '../models/api_response.dart';
import '../models/user.dart';
import 'api_service.dart';

class UserService {
  final _api = ApiService().dio;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('User service response format error');
    }
    return data;
  }

  Future<ApiResponse<UserDto>> getProfile() async {
    final response = await _api.get('/User/profile');
    return ApiResponse<UserDto>.fromJson(
      _asMap(response.data),
      (json) => UserDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<UserDto>> updateProfile(UserUpdateDto request) async {
    final response = await _api.put('/User/profile', data: request.toJson());
    return ApiResponse<UserDto>.fromJson(
      _asMap(response.data),
      (json) => UserDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<PublicUserProfileDto>> getPublicProfile(
    String userId,
  ) async {
    final response = await _api.get('/User/public/$userId');
    return ApiResponse<PublicUserProfileDto>.fromJson(
      _asMap(response.data),
      (json) => PublicUserProfileDto.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse> changePassword(ChangePasswordRequest request) async {
    final response = await _api.put('/User/password', data: request.toJson());
    return ApiResponse.fromJson(_asMap(response.data), (json) => json);
  }
}
