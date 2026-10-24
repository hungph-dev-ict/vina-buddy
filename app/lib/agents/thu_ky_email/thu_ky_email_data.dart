import 'package:smart_inbox_ai/models/agent_model.dart';

/// Thư ký Email — Chuyên gia quản lý và phân loại hộp thư Gmail.
const emailSecretaryAgentDefinition = AgentDefinition(
  id: 'thu_ky_email',
  defaultName: 'Thư ký Email',
  category: 'office_utility',
  description:
      'Chuyên gia dọn dẹp, phân loại hộp thư và gắn nhãn email tự động.',
  avatarSymbol: '📧',
  personality: AgentPersonality(
    tone: 'punctual_polite',
    style: 'professional_secretary',
  ),
  capabilities: [
    AgentCapability(
      id: 'gmail_cleanup',
      name: 'Dọn dẹp hòm thư Gmail',
      description: 'Phân loại email rác và gắn nhãn có phê duyệt.',
      requiresExternalPermission: true,
      supportedIntents: ['clean_email', 'classify_inbox', 'label_rule'],
    ),
  ],
  limitations: [
    'Chỉ thao tác khi có sự cấp quyền và phê duyệt trực tiếp của Giám đốc.',
    'Tuyệt đối không xoá hoặc gửi email.',
  ],
  requiredPermissions: ['https://www.googleapis.com/auth/gmail.modify'],
  version: 1,
  isPlaceholder: true,
);
