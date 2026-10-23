import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_inbox_ai/models/email_item.dart';
import 'package:smart_inbox_ai/models/rule_model.dart';
import 'package:smart_inbox_ai/services/api_service.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  void setLocale(Locale locale) {
    if (state != locale) {
      state = locale;
    }
  }

  void toggleLocale() {
    state = state.languageCode == 'en' ? const Locale('vi') : const Locale('en');
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class AuthState {
  final bool isAuthenticated;
  final String? email;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.email,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> loginGoogle({String? authCode}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final apiService = ref.read(apiServiceProvider);

    try {
      final code = authCode ?? 'mock_auth_code_mobile';
      final res = await apiService.loginGoogle(
        authCode: code,
        redirectUri: 'com.vinabuddy.smartinbox:/oauth2callback',
      );
      state = state.copyWith(
        isAuthenticated: true,
        email: res['email'] as String? ?? 'user@gmail.com',
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void logout() {
    ref.read(apiServiceProvider).sessionToken = null;
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

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
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final emailsProvider =
    NotifierProvider<EmailsNotifier, EmailsState>(EmailsNotifier.new);

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

final rulesProvider =
    NotifierProvider<RulesNotifier, RulesState>(RulesNotifier.new);
