import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_inbox_ai/config/constants.dart';
import 'package:smart_inbox_ai/models/email_item.dart';
import 'package:smart_inbox_ai/models/health_status.dart';
import 'package:smart_inbox_ai/models/preview_model.dart';
import 'package:smart_inbox_ai/models/reminder_model.dart';
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

  ApiService({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? AppConstants.defaultApiBaseUrl).replaceAll(
        RegExp(r'/+$'),
        '',
      ),
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
      return HealthStatus.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
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
      body: jsonEncode({'auth_code': authCode, 'redirect_uri': redirectUri}),
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

  Future<Map<String, dynamic>> getGoogleAuthUrl({
    String? serverHost,
    String? redirectUri,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/google/url').replace(
      queryParameters: {
        if (serverHost != null && serverHost.isNotEmpty)
          'server_host': serverHost,
        if (redirectUri != null && redirectUri.isNotEmpty)
          'redirect_uri': redirectUri,
      },
    );
    final res = await _client.get(uri, headers: _buildHeaders());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'URL_FAILED',
      message: errorBody['message'] ?? 'Failed to get Google Auth URL',
    );
  }

  Future<void> saveGoogleConfig({
    required String clientId,
    required String clientSecret,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/google/config');
    final res = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode({
        'client_id': clientId.trim(),
        'client_secret': clientSecret.trim(),
      }),
    );
    if (res.statusCode != 200) {
      final errorBody = _parseErrorBody(res.body);
      throw ApiException(
        statusCode: res.statusCode,
        code: errorBody['code'] ?? 'CONFIG_FAILED',
        message: errorBody['message'] ?? 'Failed to save Google configuration',
      );
    }
  }

  Future<Map<String, dynamic>> pollGoogleAuth({required String state}) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/google/poll')
        .replace(queryParameters: {'state': state});
    final res = await _client.get(uri, headers: _buildHeaders());
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] == 'completed' && data['session_token'] != null) {
        sessionToken = data['session_token'] as String?;
      }
      return data;
    }
    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'POLL_FAILED',
      message: errorBody['message'] ?? 'Failed to poll login status',
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
      return PreviewModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
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
        data['summary'] as Map<String, dynamic>,
      );
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

  Future<Map<String, dynamic>> sendAssistantMessage({
    required String message,
    String locale = 'vi',
    String? sessionId,
    String? agentId,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/assistant/chat');
    final payload = <String, dynamic>{'message': message, 'locale': locale};
    if (agentId != null) {
      payload['agent_id'] = agentId;
    }
    if (sessionId != null) {
      payload['session_id'] = sessionId;
    }
    try {
      final res = await _client
          .post(url, headers: _buildHeaders(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }

      final errorBody = _parseErrorBody(res.body);
      throw ApiException(
        statusCode: res.statusCode,
        code: errorBody['code'] ?? 'ASSISTANT_ERROR',
        message: errorBody['message'] ?? 'Failed to chat with assistant',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        code: 'TIMEOUT',
        message: 'Không thể kết nối đến máy chủ backend (quá thời gian chờ 15s). Vui lòng kiểm tra lại server!',
      );
    }
  }

  Future<List<AgentReminder>> getAgentReminders(String agentId) async {
    final url = Uri.parse('$baseUrl/api/v1/agents/$agentId/reminders');
    final res = await _client.get(url, headers: _buildHeaders());
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return data
          .map((e) => AgentReminder.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'REMINDER_FETCH_ERROR',
      message: errorBody['message'] ?? 'Failed to fetch agent reminders',
    );
  }

  Future<AgentReminder> createAgentReminder(
    String agentId,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/api/v1/agents/$agentId/reminders');
    final res = await _client.post(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) {
      return AgentReminder.fromJson(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    }
    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'REMINDER_CREATE_ERROR',
      message: errorBody['message'] ?? 'Failed to create agent reminder',
    );
  }

  Future<AgentReminder> updateAgentReminder(
    String reminderId, {
    bool? isEnabled,
    String? targetTime,
    String? occasion,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/reminders/$reminderId');
    final payload = <String, dynamic>{
      'is_enabled': ?isEnabled,
      'target_time': ?targetTime,
      'occasion': ?occasion,
    };
    final res = await _client.patch(
      url,
      headers: _buildHeaders(),
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200) {
      return AgentReminder.fromJson(
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    }
    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'REMINDER_UPDATE_ERROR',
      message: errorBody['message'] ?? 'Failed to update reminder',
    );
  }

  Future<void> deleteAgentReminder(String reminderId) async {
    final url = Uri.parse('$baseUrl/api/v1/reminders/$reminderId');
    final res = await _client.delete(url, headers: _buildHeaders());
    if (res.statusCode == 204 || res.statusCode == 200) {
      return;
    }
    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'REMINDER_DELETE_ERROR',
      message: errorBody['message'] ?? 'Failed to delete reminder',
    );
  }

  Future<Map<String, dynamic>> testRunAgentReminder(String reminderId) async {
    final url = Uri.parse('$baseUrl/api/v1/reminders/$reminderId/test-run');
    final res = await _client.post(url, headers: _buildHeaders());
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    final errorBody = _parseErrorBody(res.body);
    throw ApiException(
      statusCode: res.statusCode,
      code: errorBody['code'] ?? 'REMINDER_TEST_RUN_ERROR',
      message: errorBody['message'] ?? 'Failed to execute test run',
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
