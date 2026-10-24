import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inbox_ai/models/assistant_chat.dart';
import 'package:smart_inbox_ai/models/reminder_model.dart';

void main() {
  group('ReminderSchedule Model Tests', () {
    test('parses lunar_monthly schedule with 1 and 15 correctly', () {
      final json = {
        'type': 'lunar_monthly',
        'days': [1, 15],
      };
      final schedule = ReminderSchedule.fromJson(json);

      expect(schedule.type, 'lunar_monthly');
      expect(schedule.days, [1, 15]);
      expect(
        schedule.toReadableText(),
        'Mùng 1 & Ngày rằm (15) Âm lịch hàng tháng',
      );
      expect(schedule.toJson(), {
        'type': 'lunar_monthly',
        'days': [1, 15],
      });
    });

    test('parses lunar_yearly with month and day', () {
      final json = {
        'type': 'lunar_yearly',
        'days': [5],
        'month': 5,
      };
      final schedule = ReminderSchedule.fromJson(json);

      expect(schedule.type, 'lunar_yearly');
      expect(schedule.days, [5]);
      expect(schedule.month, 5);
      expect(schedule.toReadableText(), 'Ngày 5/5 Âm lịch hàng năm');
    });

    test('parses solar_weekly with weekday', () {
      final json = {'type': 'solar_weekly', 'weekday': 2};
      final schedule = ReminderSchedule.fromJson(json);

      expect(schedule.type, 'solar_weekly');
      expect(schedule.weekday, 2);
      expect(schedule.toReadableText(), 'Thứ 2 hàng tuần');
    });
  });

  group('AgentReminder Model Tests', () {
    test('parses complete AgentReminder json and copyWith', () {
      final json = {
        'id': 'rem_test_01',
        'agent_id': 'thay_cung',
        'title': 'Nhắc sóc vọng',
        'description': 'Tự động nhắc mùng 1 và ngày rằm',
        'schedule': {
          'type': 'lunar_monthly',
          'days': [1, 15],
        },
        'target_time': '07:00',
        'occasion': 'Sóc vọng',
        'custom_payload': {'key': 'val'},
        'is_enabled': true,
        'created_at': '2026-10-24T00:00:00.000Z',
      };

      final reminder = AgentReminder.fromJson(json);
      expect(reminder.id, 'rem_test_01');
      expect(reminder.agentId, 'thay_cung');
      expect(reminder.title, 'Nhắc sóc vọng');
      expect(reminder.targetTime, '07:00');
      expect(reminder.occasion, 'Sóc vọng');
      expect(reminder.isEnabled, true);

      final toggled = reminder.copyWith(isEnabled: false);
      expect(toggled.isEnabled, false);
      expect(toggled.id, 'rem_test_01');
    });
  });

  group('InteractiveConfigPrompt Model Tests', () {
    test('parses InteractiveConfigPrompt from chat response json', () {
      final json = {
        'config_type': 'reminder_quick_setup',
        'title': 'Chọn lịch nhắc ngày sóc vọng & rằm:',
        'is_multi_select': true,
        'options': [
          {'id': 'mung_1', 'label': 'Mùng 1 Âm lịch', 'default_checked': true},
          {
            'id': 'ngay_ram',
            'label': 'Ngày rằm (15) Âm lịch',
            'default_checked': true,
          },
        ],
        'confirm_label': 'Xác nhận lịch nhắc',
      };

      final config = InteractiveConfigPrompt.fromJson(json);
      expect(config.configType, 'reminder_quick_setup');
      expect(config.title, 'Chọn lịch nhắc ngày sóc vọng & rằm:');
      expect(config.isMultiSelect, true);
      expect(config.options.length, 2);
      expect(config.options[0].id, 'mung_1');
      expect(config.options[0].defaultChecked, true);
      expect(config.confirmLabel, 'Xác nhận lịch nhắc');
    });
  });
}
