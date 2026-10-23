import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_inbox_ai/config/constants.dart';
import 'package:smart_inbox_ai/models/email_item.dart';
import 'package:smart_inbox_ai/models/health_status.dart';
import 'package:smart_inbox_ai/models/preview_model.dart';
import 'package:smart_inbox_ai/models/rule_model.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String code;

  ApiException({
    required this.statusCode,
    required this.message,
    this.code = 'ERROR',
  });

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

class ApiService {
  final String baseUrl;
  final http.Client _client;
  String? sessionToken;

  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = (baseUrl ?? AppConstants.defaultApiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (sessionToken != null && sessionToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $sessionToken';
    }
    return headers;
  }

  Future<HealthStatus> checkHealth() async {
    final url = Uri.parse('$baseUrl/api/v1/health');
    final res = await _client.get(url, headers: _buildHeaders());
    if (res.statusCode == 200) {
      return HealthStatus.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: 'Failed to connect to backend: ${res.statusCode}',
    );
  }

  Future<Map<String, dynamic>> loginGoogle({
    required String authCode,
    required String redirectUri,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/google');
    final res = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({
        'auth_code': authCode,
        'redirect_uri': redirectUri,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      sessionToken = data['session_token'] as String?;
      return data;
    }

    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'AUTH_FAILED',
      message: errorBody['message'] ?? 'Authentication failed',
    );
  }

  Future<List<EmailItem>> syncEmails({int maxResults = 50}) async {
    final url = Uri.parse('$baseUrl/api/v1/gmail/sync');
    final res = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({'max_results': maxResults}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['emails'] as List<dynamic>?) ?? [];
      return list
          .map((e) => EmailItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'SYNC_ERROR',
      message: errorBody['message'] ?? 'Failed to sync emails',
    );
  }

  Future<RuleModel> createRule(String naturalLanguage) async {
    final url = Uri.parse('$baseUrl/api/v1/rules');
    final res = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({'natural_language': naturalLanguage}),
    );

    if (res.statusCode == 201) {
      return RuleModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }

    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'RULE_ERROR',
      message: errorBody['message'] ?? 'Failed to create rule',
    );
  }

  Future<List<RuleModel>> listRules() async {
    final url = Uri.parse('$baseUrl/api/v1/rules');
    final res = await _client.get(url, headers: _buildHeaders());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (data['rules'] as List<dynamic>?) ?? [];
      return list
          .map((e) => RuleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'RULES_FETCH_ERROR',
      message: errorBody['message'] ?? 'Failed to list rules',
    );
  }

  Future<RuleModel> toggleRule(String ruleId, bool enabled) async {
    final url = Uri.parse('$baseUrl/api/v1/rules/$ruleId?enabled=$enabled');
    final res = await _client.patch(url, headers: _buildHeaders());

    if (res.statusCode == 200) {
      return RuleModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }

    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'TOGGLE_ERROR',
      message: errorBody['message'] ?? 'Failed to toggle rule',
    );
  }

  Future<bool> deleteRule(String ruleId) async {
    final url = Uri.parse('$baseUrl/api/v1/rules/$ruleId');
    final res = await _client.delete(url, headers: _buildHeaders());
    if (res.statusCode == 204) {
      return true;
    }
    return false;
  }

  Future<PreviewModel> previewRule(String ruleId) async {
    final url = Uri.parse('$baseUrl/api/v1/classify/preview');
    final res = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({'rule_id': ruleId}),
    );

    if (res.statusCode == 200) {
      return PreviewModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }

    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'PREVIEW_ERROR',
      message: errorBody['message'] ?? 'Failed to preview rule',
    );
  }

  Future<ApplySummaryModel> applyApprovedActions({
    required String ruleId,
    required List<String> approvedEmailIds,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/classify/apply');
    final res = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({
        'rule_id': ruleId,
        'approved_email_ids': approvedEmailIds,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ApplySummaryModel.fromJson(
          data['summary'] as Map<String, dynamic>);
    }

    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'APPLY_ERROR',
      message: errorBody['message'] ?? 'Failed to apply actions',
    );
  }

  Future<Map<String, dynamic>> submitAdminReport({
    required String userInput,
    String? reason,
    String? userNotes,
    String? userEmail,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/reports');
    final res = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({
        'user_input': userInput,
        'reason': reason ?? 'unsupported_content',
        'user_notes': userNotes,
        'user_email': userEmail,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'REPORT_ERROR',
      message: errorBody['message'] ?? 'Failed to submit report',
    );
  }

  Map<String, String> _parseErrorBody(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        if (json.containsKey('detail') && json['detail'] is Map) {
          final detail = json['detail'] as Map;
          return {
            'code': detail['code']?.toString() ?? 'ERROR',
            'message': detail['message']?.toString() ?? 'An error occurred',
          };
        } else if (json.containsKey('detail')) {
          return {'code': 'ERROR', 'message': json['detail'].toString()};
        }
      }
    } catch (_) {}
    return {'code': 'ERROR', 'message': 'Request failed'};
  }
}
