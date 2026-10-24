import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/services/agent_catalog_service.dart';

void main() {
  group('AgentCatalogService Unit Tests', () {
    late AgentCatalogService service;

    setUp(() {
      service = AgentCatalogService();
    });

    test('Loads catalog with thay_cung and placeholders', () {
      final agents = service.getAllAgents();
      expect(agents.isNotEmpty, true);

      final thayCung = service.getAgentById('thay_cung');
      expect(thayCung, isNotNull);
      expect(thayCung!.defaultName, 'Thầy Cúng');
      expect(thayCung.isPlaceholder, false);
      expect(thayCung.capabilities.length, 4);

      final thuKy = service.getAgentById('thu_ky_email');
      expect(thuKy, isNotNull);
      expect(thuKy!.isPlaceholder, true);
    });

    test('findMatchingAgentForQuery returns thay_cung for lunar keywords', () {
      final match = service.findMatchingAgentForQuery('Hôm nay ngày mấy rằm');
      expect(match?.id, 'thay_cung');

      final match2 = service.findMatchingAgentForQuery('Xin bài cúng mùng 1');
      expect(match2?.id, 'thay_cung');
    });

    test(
      'findMatchingAgentForQuery returns thu_ky_email for email keywords',
      () {
        final match = service.findMatchingAgentForQuery(
          'Quản lý email và gắn nhãn Shopee',
        );
        expect(match?.id, 'thu_ky_email');
      },
    );
  });
}
