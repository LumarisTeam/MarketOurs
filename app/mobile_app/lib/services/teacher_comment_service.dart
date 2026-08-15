import '../models/api_response.dart';
import '../models/paged_result.dart';
import '../models/teacher_comment.dart';
import 'api_service.dart';

class TeacherCommentService {
  final _api = ApiService().dio;

  Future<ApiResponse<TeacherCommentItem>> createTeacherComment(
    CreateTeacherCommentRequest request,
  ) async {
    final response = await _api.post('/TeacherComment', data: request.toJson());
    return ApiResponse<TeacherCommentItem>.fromJson(
      response.data,
      (json) => TeacherCommentItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<TeacherCommentItem>> updateTeacherComment(
    String key,
    UpdateTeacherCommentRequest request,
  ) async {
    final response = await _api.put('/TeacherComment/$key', data: request.toJson());
    return ApiResponse<TeacherCommentItem>.fromJson(
      response.data,
      (json) => TeacherCommentItem.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<TeacherCommentItem>>> getMyComments() async {
    final response = await _api.get('/TeacherComment/mine');
    return ApiResponse<List<TeacherCommentItem>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => TeacherCommentItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Future<ApiResponse<List<TeacherCommentItem>>> getUserComments(
    String userId,
  ) async {
    final encodedId = Uri.encodeComponent(userId);
    final response = await _api.get('/TeacherComment/user/$encodedId');
    return ApiResponse<List<TeacherCommentItem>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => TeacherCommentItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Future<ApiResponse<List<TeacherCommentItem>>> getTeacherComments(
    String teacherName,
  ) async {
    final encodedName = Uri.encodeComponent(teacherName);
    final response = await _api.get('/TeacherComment/teacher/$encodedName');
    return ApiResponse<List<TeacherCommentItem>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => TeacherCommentItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Future<ApiResponse<PagedResult<TeacherCommentItem>>> searchApprovedComments({
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _api.get(
      '/TeacherComment/search',
      queryParameters: {'keyword': keyword, 'page': page, 'pageSize': pageSize}
        ..removeWhere((_, value) => value == null),
    );
    return ApiResponse<PagedResult<TeacherCommentItem>>.fromJson(
      response.data,
      (json) => PagedResult<TeacherCommentItem>.fromJson(
        json as Map<String, dynamic>,
        (item) => TeacherCommentItem.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<TeacherCommentSummary>> getSummary(
    String teacherName,
  ) async {
    final response = await _api.get(
      '/TeacherComment/summary',
      queryParameters: {'teacherName': teacherName},
    );
    return ApiResponse<TeacherCommentSummary>.fromJson(
      response.data,
      (json) => TeacherCommentSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse> deleteTeacherComment(String key) async {
    final response = await _api.delete('/TeacherComment/$key');
    return ApiResponse.fromJson(response.data, (json) => json);
  }

  Future<ApiResponse<PagedResult<TeacherCommentItem>>> getAdminComments({
    int page = 1,
    int pageSize = 20,
    String? teacherName,
    String? courseName,
    bool? isReview,
    int? minStar,
  }) async {
    final response = await _api.get(
      '/TeacherComment/admin/list',
      queryParameters: {
        'Page': page,
        'PageSize': pageSize,
        'TeacherName': teacherName,
        'CourseName': courseName,
        'IsReview': isReview,
        'MinStar': minStar,
      }..removeWhere((_, value) => value == null),
    );
    return ApiResponse<PagedResult<TeacherCommentItem>>.fromJson(
      response.data,
      (json) => PagedResult<TeacherCommentItem>.fromJson(
        json as Map<String, dynamic>,
        (item) => TeacherCommentItem.fromJson(item as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<List<TeacherCommentItem>>>
  getPendingAdminComments() async {
    final response = await _api.get('/TeacherComment/admin/pending');
    return ApiResponse<List<TeacherCommentItem>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map(
            (item) => TeacherCommentItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Future<ApiResponse<TeacherCommentItem>> reviewAdminComment(
    String key,
    ReviewTeacherCommentRequest request,
  ) async {
    final response = await _api.put(
      '/TeacherComment/admin/review/$key',
      data: request.toJson(),
    );
    return ApiResponse<TeacherCommentItem>.fromJson(
      response.data,
      (json) => TeacherCommentItem.fromJson(json as Map<String, dynamic>),
    );
  }
}
