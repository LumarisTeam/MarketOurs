import '../models/api_response.dart';
import '../models/report.dart';
import 'api_service.dart';

class ReportService {
  final _api = ApiService().dio;
  Future<ApiResponse> createReport(CreateReportRequest request) async {
    final response = await _api.post('/Report', data: request.toJson());
    return ApiResponse.fromJson(response.data, (json) => json);
  }
}
