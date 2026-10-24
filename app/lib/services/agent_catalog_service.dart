import 'package:smart_inbox_ai/agents/it_support/it_support_data.dart';
import 'package:smart_inbox_ai/agents/ke_toan/ke_toan_data.dart';
import 'package:smart_inbox_ai/agents/thay_cung/thay_cung_data.dart';
import 'package:smart_inbox_ai/agents/thu_ky_email/thu_ky_email_data.dart';
import 'package:smart_inbox_ai/models/agent_model.dart';

/// Aggregates modular agent definitions from individual agent folders in `lib/agents/`.
class AgentCatalogService {
  static final AgentCatalogService _instance = AgentCatalogService._internal();
  factory AgentCatalogService() => _instance;
  AgentCatalogService._internal();

  static const thayCungAgent = thayCungAgentDefinition;
  static const emailSecretaryPlaceholder = emailSecretaryAgentDefinition;
  static const spendingAccountantPlaceholder =
      spendingAccountantAgentDefinition;
  static const itSupportPlaceholder = itSupportAgentDefinition;

  final List<AgentDefinition> _catalog = [
    thayCungAgentDefinition,
    emailSecretaryAgentDefinition,
    spendingAccountantAgentDefinition,
    itSupportAgentDefinition,
  ];

  List<AgentDefinition> getAllAgents() => List.unmodifiable(_catalog);

  AgentDefinition? getAgentById(String id) {
    try {
      return _catalog.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Finds suitable agent in catalog for an intent or query
  AgentDefinition? findMatchingAgentForQuery(String query) {
    final lower = query.toLowerCase();

    // Queries completely outside office scope (travel, gym)
    if (lower.contains('vé máy bay') ||
        lower.contains('khách sạn') ||
        lower.contains('du lịch') ||
        lower.contains('gym')) {
      return null;
    }

    if (lower.contains('gmail') ||
        lower.contains('email') ||
        lower.contains('thư') ||
        lower.contains('hộp thư')) {
      return emailSecretaryAgentDefinition;
    }
    if (lower.contains('tiền') ||
        lower.contains('chi tiêu') ||
        lower.contains('ngân sách') ||
        lower.contains('lương')) {
      return spendingAccountantAgentDefinition;
    }
    if (lower.contains('máy tính') ||
        lower.contains('wifi') ||
        lower.contains('mạng') ||
        lower.contains('lỗi máy')) {
      return itSupportAgentDefinition;
    }
    if (lower.contains('rằm') ||
        lower.contains('mùng 1') ||
        lower.contains('âm lịch') ||
        lower.contains('cúng') ||
        lower.contains('khấn') ||
        lower.contains('lễ')) {
      return thayCungAgentDefinition;
    }
    return null;
  }
}
