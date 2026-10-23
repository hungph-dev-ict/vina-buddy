class HealthStatus {
  final String status;
  final String ollama;
  final String version;

  const HealthStatus({
    required this.status,
    required this.ollama,
    required this.version,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String? ?? 'unknown',
      ollama: json['ollama'] as String? ?? 'disconnected',
      version: json['version'] as String? ?? '0.0.0',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'ollama': ollama,
    'version': version,
  };
}
