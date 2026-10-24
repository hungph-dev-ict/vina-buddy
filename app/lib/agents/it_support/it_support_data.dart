import 'package:smart_inbox_ai/models/agent_model.dart';

/// IT Helpdesk — Hỗ trợ kỹ thuật, máy tính và mạng văn phòng.
const itSupportAgentDefinition = AgentDefinition(
  id: 'it_support',
  defaultName: 'IT Helpdesk',
  category: 'tech_support',
  description: 'Hỗ trợ khắc phục lỗi máy tính, mạng văn phòng và nhắc sếp khởi động lại máy.',
  avatarSymbol: '💻',
  personality: AgentPersonality(
    tone: 'direct_techy',
    style: 'it_troubleshooter',
  ),
  capabilities: [
    AgentCapability(
      id: 'tech_troubleshoot',
      name: 'Khắc phục sự cố kỹ thuật',
      description: 'Chẩn đoán mạng và phần mềm công sở.',
      supportedIntents: ['troubleshoot_pc', 'network_issue'],
    ),
  ],
  limitations: ['Không sửa được đường truyền khi cá mập cắn cáp quang biển.'],
  requiredPermissions: [],
  version: 1,
  isPlaceholder: true,
);
