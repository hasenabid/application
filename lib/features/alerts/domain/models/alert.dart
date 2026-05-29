enum AlertSeverity { info, warning, critical }
enum AlertStatus { active, resolved }

class Alert {
  final String id;
  final String zoneId;
  final String message;
  final DateTime timestamp;
  final AlertSeverity severity;
  final AlertStatus status;

  const Alert({
    required this.id,
    required this.zoneId,
    required this.message,
    required this.timestamp,
    required this.severity,
    required this.status,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      zoneId: json['zoneId'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      status: AlertStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AlertStatus.active,
      ),
    );
  }
}
