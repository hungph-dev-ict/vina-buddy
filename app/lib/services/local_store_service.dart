import 'dart:convert';
import 'dart:io';

import 'package:smart_inbox_ai/config/constants.dart';
import 'package:smart_inbox_ai/models/agent_model.dart';

class LocalStoreService {
  static final LocalStoreService _instance = LocalStoreService._internal();
  factory LocalStoreService() => _instance;
  LocalStoreService._internal();

  String _assistantName = AppConstants.defaultAssistantName;
  bool _isOnboarded = false;
  final Map<String, RecruitedAgent> _recruitedAgents = {};
  final Map<String, List<Map<String, dynamic>>> _chatHistories = {};

  File? _storeFile;

  String get assistantName => _assistantName;
  bool get isOnboarded => _isOnboarded;
  List<RecruitedAgent> get recruitedAgents => _recruitedAgents.values.toList();

  Future<void> init({File? customFile}) async {
    try {
      if (customFile != null) {
        _storeFile = customFile;
      } else {
        // Fallback to system temp directory for on-device local storage without external plugins
        final dir = Directory.systemTemp;
        _storeFile = File('${dir.path}/vnverse_local_store.json');
      }

      if (_storeFile != null && await _storeFile!.exists()) {
        final content = await _storeFile!.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          _assistantName =
              data['assistantName'] as String? ??
              AppConstants.defaultAssistantName;
          _isOnboarded = data['isOnboarded'] as bool? ?? false;

          final list = (data['recruitedAgents'] as List<dynamic>?) ?? [];
          _recruitedAgents.clear();
          for (final item in list) {
            final agent = RecruitedAgent.fromJson(item as Map<String, dynamic>);
            _recruitedAgents[agent.agentId] = agent;
          }

          final histories =
              (data['chatHistories'] as Map<String, dynamic>?) ?? {};
          _chatHistories.clear();
          histories.forEach((k, v) {
            if (v is List) {
              _chatHistories[k] = v
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            }
          });
        }
      }
    } catch (_) {
      // Gracefully fall back to in-memory state on file read error
    }
  }

  Future<void> _persist() async {
    try {
      if (_storeFile != null) {
        final data = {
          'assistantName': _assistantName,
          'isOnboarded': _isOnboarded,
          'recruitedAgents': _recruitedAgents.values
              .map((a) => a.toJson())
              .toList(),
          'chatHistories': _chatHistories,
        };
        await _storeFile!.writeAsString(jsonEncode(data), flush: true);
      }
    } catch (_) {
      // In-memory state remains safe if file IO fails
    }
  }

  Future<void> setAssistantName(String name) async {
    final clean = name.trim();
    if (clean.isNotEmpty) {
      _assistantName = clean;
      _isOnboarded = true;
      await _persist();
    }
  }

  Future<void> setOnboarded(bool value) async {
    _isOnboarded = value;
    await _persist();
  }

  Future<bool> recruitAgent(String agentId, String defaultName) async {
    if (_recruitedAgents.containsKey(agentId)) {
      final existing = _recruitedAgents[agentId]!;
      if (existing.isDismissed) {
        _recruitedAgents[agentId] = existing.copyWith(
          customDisplayName: defaultName,
          isDismissed: false,
          dismissedAt: null,
        );
        await _persist();
        return true;
      }
      return false; // Prevent duplicate recruitment if already active
    }
    final agent = RecruitedAgent(
      agentId: agentId,
      customDisplayName: defaultName,
      recruitedAt: DateTime.now(),
      isDismissed: false,
    );
    _recruitedAgents[agentId] = agent;
    await _persist();
    return true;
  }

  Future<bool> dismissAgent(String agentId) async {
    if (!_recruitedAgents.containsKey(agentId)) {
      return false;
    }
    final existing = _recruitedAgents[agentId]!;
    _recruitedAgents[agentId] = existing.copyWith(
      isDismissed: true,
      dismissedAt: DateTime.now(),
    );
    await _persist();
    return true;
  }

  Future<bool> renameRecruitedAgent(String agentId, String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty || !_recruitedAgents.containsKey(agentId)) {
      return false;
    }
    _recruitedAgents[agentId] = _recruitedAgents[agentId]!.copyWith(
      customDisplayName: clean,
    );
    await _persist();
    return true;
  }

  bool isAgentRecruited(String agentId) {
    final agent = _recruitedAgents[agentId];
    return agent != null && !agent.isDismissed;
  }

  bool isAgentDismissed(String agentId) {
    final agent = _recruitedAgents[agentId];
    return agent != null && agent.isDismissed;
  }

  RecruitedAgent? getRecruitedAgent(String agentId) {
    return _recruitedAgents[agentId];
  }

  List<Map<String, dynamic>> getChatHistory(String agentId) {
    return _chatHistories[agentId] ?? [];
  }

  Future<void> saveChatHistory(
    String agentId,
    List<Map<String, dynamic>> messages,
  ) async {
    _chatHistories[agentId] = messages;
    await _persist();
  }

  void clearForTest() {
    _assistantName = AppConstants.defaultAssistantName;
    _isOnboarded = false;
    _recruitedAgents.clear();
    _chatHistories.clear();
  }
}
