class EmailItem {
  final String id;
  final String threadId;
  final String fromEmail;
  final String fromName;
  final String subject;
  final String snippet;
  final String date;
  final List<String> labels;
  final bool hasAttachments;

  const EmailItem({
    required this.id,
    required this.threadId,
    required this.fromEmail,
    required this.fromName,
    required this.subject,
    required this.snippet,
    required this.date,
    required this.labels,
    this.hasAttachments = false,
  });

  factory EmailItem.fromJson(Map<String, dynamic> json) {
    return EmailItem(
      id: json['id'] as String? ?? '',
      threadId: json['thread_id'] as String? ?? '',
      fromEmail: json['from_email'] as String? ?? '',
      fromName: json['from_name'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      date: json['date'] as String? ?? '',
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hasAttachments: json['has_attachments'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'thread_id': threadId,
        'from_email': fromEmail,
        'from_name': fromName,
        'subject': subject,
        'snippet': snippet,
        'date': date,
        'labels': labels,
        'has_attachments': hasAttachments,
      };
}
