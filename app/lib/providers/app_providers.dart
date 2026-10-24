import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/config/constants.dart';
import 'package:smart_inbox_ai/models/agent_model.dart';
import 'package:smart_inbox_ai/models/assistant_chat.dart';
import 'package:smart_inbox_ai/models/email_item.dart';
import 'package:smart_inbox_ai/models/reminder_model.dart';
import 'package:smart_inbox_ai/models/rule_model.dart';
import 'package:smart_inbox_ai/services/agent_catalog_service.dart';
import 'package:smart_inbox_ai/services/api_service.dart';
import 'package:smart_inbox_ai/services/local_store_service.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  void setLocale(Locale locale) {
    if (state != locale) {
      state = locale;
    }
  }

  void toggleLocale() {
    state = state.languageCode == 'en'
        ? const Locale('vi')
        : const Locale('en');
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    if (state != mode) {
      state = mode;
    }
  }

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ServerUrlNotifier extends Notifier<String> {
  @override
  String build() => AppConstants.defaultApiBaseUrl;

  void setBaseUrl(String newUrl) {
    final clean = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isNotEmpty) {
      state = clean;
    }
  }
}

final serverUrlProvider = NotifierProvider<ServerUrlNotifier, String>(
  ServerUrlNotifier.new,
);

final apiServiceProvider = Provider<ApiService>((ref) {
  final baseUrl = ref.watch(serverUrlProvider);
  return ApiService(baseUrl: baseUrl);
});

class AuthState {
  final bool isAuthenticated;
  final String? email;
  final bool isGoogleLoading;
  final bool isDevLoading;
  final String? errorMessage;

  bool get isLoading => isGoogleLoading || isDevLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.email,
    this.isGoogleLoading = false,
    this.isDevLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    bool? isGoogleLoading,
    bool? isDevLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      isDevLoading: isDevLoading ?? this.isDevLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void setAuthenticated({required String email, required String sessionToken}) {
    final apiService = ref.read(apiServiceProvider);
    apiService.sessionToken = sessionToken;
    state = state.copyWith(
      isAuthenticated: true,
      email: email,
      isGoogleLoading: false,
      isDevLoading: false,
      errorMessage: null,
    );
  }

  void setGoogleLoading(bool loading) {
    state = state.copyWith(isGoogleLoading: loading);
  }

  Future<bool> loginGoogle({String? email, String? authCode}) async {
    state = state.copyWith(
      isGoogleLoading: true,
      isDevLoading: false,
      errorMessage: null,
    );
    final apiService = ref.read(apiServiceProvider);

    try {
      final String code;
      if (authCode != null && authCode.isNotEmpty) {
        code = authCode;
      } else if (email != null && email.trim().isNotEmpty) {
        code = 'email:${email.trim()}';
      } else {
        code = 'mock_auth_code_mobile';
      }

      final res = await apiService.loginGoogle(
        authCode: code,
        redirectUri: 'com.vinabuddy.smartinbox:/oauth2callback',
      );
      state = state.copyWith(
        isAuthenticated: true,
        email: res['email'] as String? ?? (email ?? 'user@gmail.com'),
        isGoogleLoading: false,
      );
      return true;
    } catch (e) {
      final msg = e.toString();
      final userFriendlyMsg = msg.contains('10.0.2.2')
          ? 'Không thể kết nối đến máy chủ 10.0.2.2:8000 (Địa chỉ này chỉ dành cho máy ảo Emulator).\n\nTrên máy thật, vui lòng nhấn "Server: ..." ở dưới để đổi sang IP máy Mac (vd: http://192.168.1.109:8000) hoặc link ngrok.'
          : msg;
      state = state.copyWith(
        isGoogleLoading: false,
        errorMessage: userFriendlyMsg,
      );
      return false;
    }
  }

  Future<bool> loginDevMode() async {
    state = state.copyWith(
      isDevLoading: true,
      isGoogleLoading: false,
      errorMessage: null,
    );
    final apiService = ref.read(apiServiceProvider);

    try {
      final res = await apiService.loginGoogle(
        authCode: 'mock_sandbox_tester_code',
        redirectUri: 'com.vinabuddy.smartinbox:/oauth2callback',
      );
      state = state.copyWith(
        isAuthenticated: true,
        email: res['email'] as String? ?? 'dev.sandbox@vinabuddy.ai',
        isDevLoading: false,
      );
      return true;
    } catch (e) {
      final msg = e.toString();
      final userFriendlyMsg = msg.contains('10.0.2.2')
          ? 'Không thể kết nối đến máy chủ 10.0.2.2:8000 (Địa chỉ này chỉ dành cho máy ảo Emulator).\n\nTrên máy thật, vui lòng nhấn "Server: ..." ở dưới để đổi sang IP máy Mac (vd: http://192.168.1.109:8000) hoặc link ngrok.'
          : msg;
      state = state.copyWith(
        isDevLoading: false,
        errorMessage: userFriendlyMsg,
      );
      return false;
    }
  }

  void enterOfflineSandbox() {
    state = state.copyWith(
      isAuthenticated: true,
      email: 'sandbox.offline@vinabuddy.ai',
      isGoogleLoading: false,
      isDevLoading: false,
      errorMessage: null,
    );
  }

  void logout() {
    ref.read(apiServiceProvider).sessionToken = null;
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class EmailsState {
  final List<EmailItem> emails;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  const EmailsState({
    this.emails = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastSyncedAt,
  });

  EmailsState copyWith({
    List<EmailItem>? emails,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastSyncedAt,
  }) {
    return EmailsState(
      emails: emails ?? this.emails,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class EmailsNotifier extends Notifier<EmailsState> {
  @override
  EmailsState build() => const EmailsState();

  Future<void> syncEmails({int maxResults = 50}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final apiService = ref.read(apiServiceProvider);

    try {
      final items = await apiService.syncEmails(maxResults: maxResults);
      state = state.copyWith(
        emails: items,
        isLoading: false,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final emailsProvider = NotifierProvider<EmailsNotifier, EmailsState>(
  EmailsNotifier.new,
);

class RulesState {
  final List<RuleModel> rules;
  final bool isLoading;
  final String? errorMessage;

  const RulesState({
    this.rules = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RulesState copyWith({
    List<RuleModel>? rules,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RulesState(
      rules: rules ?? this.rules,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class RulesNotifier extends Notifier<RulesState> {
  @override
  RulesState build() => const RulesState();

  Future<void> fetchRules() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final apiService = ref.read(apiServiceProvider);

    try {
      final items = await apiService.listRules();
      state = state.copyWith(rules: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<RuleModel?> createRule(String naturalLanguage) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final apiService = ref.read(apiServiceProvider);

    try {
      final rule = await apiService.createRule(naturalLanguage);
      final allCreated = [rule, ...rule.subRules];
      state = state.copyWith(
        rules: [...allCreated, ...state.rules],
        isLoading: false,
      );
      return rule;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<void> toggleRule(String ruleId, bool enabled) async {
    final apiService = ref.read(apiServiceProvider);

    try {
      final updated = await apiService.toggleRule(ruleId, enabled);
      state = state.copyWith(
        rules: state.rules.map((r) => r.id == ruleId ? updated : r).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteRule(String ruleId) async {
    final apiService = ref.read(apiServiceProvider);

    try {
      await apiService.deleteRule(ruleId);
      state = state.copyWith(
        rules: state.rules.where((r) => r.id != ruleId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final rulesProvider = NotifierProvider<RulesNotifier, RulesState>(
  RulesNotifier.new,
);

class PlatformOverrideNotifier extends Notifier<TargetPlatform?> {
  @override
  TargetPlatform? build() => null;

  void setPlatform(TargetPlatform? platform) {
    state = platform;
  }
}

final platformOverrideProvider =
    NotifierProvider<PlatformOverrideNotifier, TargetPlatform?>(
      PlatformOverrideNotifier.new,
    );

class ChatAssistantState {
  final List<AssistantMessage> messages;
  final bool isSending;
  final String? errorMessage;

  const ChatAssistantState({
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
  });

  ChatAssistantState copyWith({
    List<AssistantMessage>? messages,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatAssistantState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}

class ChatAssistantNotifier extends Notifier<ChatAssistantState> {
  @override
  ChatAssistantState build() {
    return const ChatAssistantState();
  }

  void initializeWelcome(String welcomeText) {
    if (state.messages.isEmpty) {
      final welcome = AssistantMessage(
        id: 'msg_welcome',
        role: 'assistant',
        text: welcomeText,
        timestamp: DateTime.now(),
        intent: AssistantIntent.other,
        actionType: 'unsupported',
        suggestedActions: const ['stats', 'classify', 'label'],
      );
      state = state.copyWith(messages: [welcome]);
    }
  }

  Future<void> sendMessage(String text, {String? locale}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMsg = AssistantMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      text: trimmed,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isSending: true,
      errorMessage: null,
    );

    final apiService = ref.read(apiServiceProvider);
    final activeLocale = locale ?? ref.read(localeProvider).languageCode;

    try {
      final res = await apiService.sendAssistantMessage(
        message: trimmed,
        locale: activeLocale,
      );

      final assistantMsg = AssistantMessage.fromChatResponse(
        id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
        json: res,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isSending: false,
      );
    } catch (e) {
      final errorMsg = AssistantMessage(
        id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        text: 'Có lỗi xảy ra khi kết nối tới VinaBuddy. Vui lòng thử lại sau!',
        timestamp: DateTime.now(),
        actionType: 'error',
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isSending: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> applyProposal(
    String messageId,
    CleanupProposalData proposal,
  ) async {
    final apiService = ref.read(apiServiceProvider);
    try {
      await apiService.applyApprovedActions(
        ruleId: proposal.ruleId,
        approvedEmailIds: proposal.matchedEmailIds,
      );
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == messageId && m.proposal != null) {
            return m.copyWith(proposal: m.proposal!.copyWith(isApplied: true));
          }
          return m;
        }).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void addExternalMessage(AssistantMessage msg) {
    state = state.copyWith(messages: [...state.messages, msg]);
  }
}

final chatAssistantProvider =
    NotifierProvider<ChatAssistantNotifier, ChatAssistantState>(
      ChatAssistantNotifier.new,
    );

// -----------------------------------------------------------------------------
// vnverse Core Services & Providers
// -----------------------------------------------------------------------------

final localStoreServiceProvider = Provider<LocalStoreService>((ref) {
  return LocalStoreService();
});

final agentCatalogServiceProvider = Provider<AgentCatalogService>((ref) {
  return AgentCatalogService();
});

class CoordinatorNameNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.read(localStoreServiceProvider).assistantName;
  }

  Future<void> setName(String newName) async {
    final clean = newName.trim();
    if (clean.isNotEmpty && clean != state) {
      state = clean;
      await ref.read(localStoreServiceProvider).setAssistantName(clean);
    }
  }
}

final coordinatorNameProvider =
    NotifierProvider<CoordinatorNameNotifier, String>(
      CoordinatorNameNotifier.new,
    );

class IsOnboardedNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(localStoreServiceProvider).isOnboarded;
  }

  Future<void> setOnboarded(bool value) async {
    state = value;
    await ref.read(localStoreServiceProvider).setOnboarded(value);
  }
}

final isOnboardedProvider = NotifierProvider<IsOnboardedNotifier, bool>(
  IsOnboardedNotifier.new,
);

class RecruitedAgentsNotifier extends Notifier<List<RecruitedAgent>> {
  @override
  List<RecruitedAgent> build() {
    return ref.read(localStoreServiceProvider).recruitedAgents;
  }

  Future<bool> recruit(String agentId, String defaultName) async {
    final success = await ref
        .read(localStoreServiceProvider)
        .recruitAgent(agentId, defaultName);
    if (success) {
      state = ref.read(localStoreServiceProvider).recruitedAgents;
    }
    return success;
  }

  Future<bool> renameAgent(String agentId, String newName) async {
    final success = await ref
        .read(localStoreServiceProvider)
        .renameRecruitedAgent(agentId, newName);
    if (success) {
      state = ref.read(localStoreServiceProvider).recruitedAgents;
    }
    return success;
  }

  Future<bool> dismiss(String agentId) async {
    final success = await ref
        .read(localStoreServiceProvider)
        .dismissAgent(agentId);
    if (success) {
      state = ref.read(localStoreServiceProvider).recruitedAgents;
    }
    return success;
  }

  bool isRecruited(String agentId) {
    return state.any((a) => a.agentId == agentId && !a.isDismissed);
  }

  bool isDismissed(String agentId) {
    return state.any((a) => a.agentId == agentId && a.isDismissed);
  }

  String getDisplayName(String agentId, String fallback) {
    for (final a in state) {
      if (a.agentId == agentId) return a.customDisplayName;
    }
    return fallback;
  }
}

final recruitedAgentsProvider =
    NotifierProvider<RecruitedAgentsNotifier, List<RecruitedAgent>>(
      RecruitedAgentsNotifier.new,
    );

class AgentChatNotifier extends Notifier<ChatAssistantState> {
  AgentChatNotifier(this.agentId);

  final String agentId;

  @override
  ChatAssistantState build() {
    return const ChatAssistantState();
  }

  void initialize(String welcomeText) {
    if (state.messages.isEmpty) {
      final welcome = AssistantMessage(
        id: 'msg_welcome_$agentId',
        role: 'assistant',
        text: welcomeText,
        timestamp: DateTime.now(),
        agentId: agentId,
      );
      state = state.copyWith(messages: [welcome]);
    }
  }

  Future<void> sendMessage(String text, {String? locale}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMsg = AssistantMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      text: trimmed,
      timestamp: DateTime.now(),
      agentId: agentId,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isSending: true,
      errorMessage: null,
    );

    final apiService = ref.read(apiServiceProvider);
    final activeLocale = locale ?? ref.read(localeProvider).languageCode;

    try {
      final res = await apiService.sendAssistantMessage(
        message: trimmed,
        locale: activeLocale,
        agentId: agentId,
      );

      final assistantMsg = AssistantMessage.fromChatResponse(
        id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
        json: res,
        agentId: agentId,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isSending: false,
      );

      // Check if handoff required and notify Coordinator
      final recId = assistantMsg.recommendAgentId;
      final handoffRaw = res['handoff'] as Map<String, dynamic>?;
      final isHandoff =
          (handoffRaw != null && handoffRaw['handoffRequired'] == true) ||
          recId != null;

      if (isHandoff && agentId != AppConstants.coordinatorAgentId) {
        final coordNotifier = ref.read(chatAssistantProvider.notifier);
        final catalog = ref.read(agentCatalogServiceProvider);
        final recAgent = recId != null ? catalog.getAgentById(recId) : null;
        final currentAgent = catalog.getAgentById(agentId);
        final currentAgentName = currentAgent?.defaultName ?? agentId;

        String coordExplanation =
            'Thưa Giám đốc! $currentAgentName vừa chuyển tiếp một yêu cầu của sếp: "$trimmed".\n\n';
        if (recAgent != null) {
          final isRecruited = ref
              .read(recruitedAgentsProvider.notifier)
              .isRecruited(recAgent.id);
          if (isRecruited) {
            coordExplanation +=
                'Em thấy sếp đã tuyển dụng **${recAgent.defaultName}** rồi. Sếp có thể qua mục Bạn bè để giao việc trực tiếp nhé!';
          } else {
            coordExplanation +=
                'Để xử lý việc này, sếp nên tuyển **${recAgent.defaultName}** (${recAgent.description}). Nhân sự này hiện có sẵn bên Chợ tuyển dụng sếp nhé!';
          }
        } else {
          coordExplanation += 'Skill này hiện em không có, để em báo Bộ trưởng chiêu mộ thêm nhân tài nước ngoài về phục vụ sếp nhé!';
        }

        coordNotifier.addExternalMessage(
          AssistantMessage(
            id: 'msg_handoff_${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            text: coordExplanation,
            timestamp: DateTime.now(),
            agentId: AppConstants.coordinatorAgentId,
            recommendAgentId: recId,
          ),
        );
      }
    } catch (e) {
      final errorMsg = AssistantMessage(
        id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        text: 'Có lỗi xảy ra khi kết nối tới vnverse. Vui lòng thử lại sau!',
        timestamp: DateTime.now(),
        actionType: 'error',
        agentId: agentId,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isSending: false,
        errorMessage: e.toString(),
      );
    }
  }

  void addExternalMessage(AssistantMessage msg) {
    state = state.copyWith(messages: [...state.messages, msg]);
  }
}

final agentChatFamilyProvider =
    NotifierProvider.family<AgentChatNotifier, ChatAssistantState, String>(
      (arg) => AgentChatNotifier(arg),
    );

class AgentRemindersState {
  final List<AgentReminder> reminders;
  final bool isLoading;
  final String? errorMessage;
  final String? actionSuccessMessage;

  const AgentRemindersState({
    this.reminders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.actionSuccessMessage,
  });

  AgentRemindersState copyWith({
    List<AgentReminder>? reminders,
    bool? isLoading,
    String? errorMessage,
    String? actionSuccessMessage,
  }) {
    return AgentRemindersState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      actionSuccessMessage: actionSuccessMessage,
    );
  }
}

class AgentRemindersNotifier extends Notifier<AgentRemindersState> {
  AgentRemindersNotifier(this.agentId);

  final String agentId;

  @override
  AgentRemindersState build() {
    Future.microtask(() => loadReminders());
    return const AgentRemindersState(isLoading: true);
  }

  Future<void> loadReminders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiServiceProvider);
      final list = await api.getAgentReminders(agentId);
      state = state.copyWith(reminders: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> toggleReminder(String reminderId, bool isEnabled) async {
    try {
      final api = ref.read(apiServiceProvider);
      final updated = await api.updateAgentReminder(
        reminderId,
        isEnabled: isEnabled,
      );
      state = state.copyWith(
        reminders: state.reminders
            .map((r) => r.id == reminderId ? updated : r)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteReminder(String reminderId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteAgentReminder(reminderId);
      state = state.copyWith(
        reminders: state.reminders.where((r) => r.id != reminderId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<String?> testRunReminder(String reminderId) async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.testRunAgentReminder(reminderId);
      final msg = res['message'] as String? ?? 'Chạy thử thành công!';
      state = state.copyWith(actionSuccessMessage: msg);
      return msg;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> createReminder(Map<String, dynamic> data) async {
    try {
      final api = ref.read(apiServiceProvider);
      final created = await api.createAgentReminder(agentId, data);
      state = state.copyWith(reminders: [...state.reminders, created]);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final agentRemindersFamilyProvider =
    NotifierProvider.family<
      AgentRemindersNotifier,
      AgentRemindersState,
      String
    >((arg) => AgentRemindersNotifier(arg));
