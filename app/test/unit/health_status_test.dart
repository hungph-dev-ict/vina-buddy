import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/models/health_status.dart';

void main() {
  group('HealthStatus Model', () {
    test('parses JSON correctly', () {
      final json = {
        'status': 'healthy',
        'ollama': 'connected',
        'version': '0.1.0',
      };
      final health = HealthStatus.fromJson(json);
      expect(health.status, 'healthy');
      expect(health.ollama, 'connected');
      expect(health.version, '0.1.0');
    });

    test('serializes to JSON correctly', () {
      const health = HealthStatus(
        status: 'healthy',
        ollama: 'connected',
        version: '0.1.0',
      );
      final json = health.toJson();
      expect(json['status'], 'healthy');
      expect(json['ollama'], 'connected');
      expect(json['version'], '0.1.0');
    });
  });
}
