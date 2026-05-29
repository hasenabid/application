class AuditLog {
  final String id;
  final String action;
  final DateTime timestamp;
  final String userName;
  final String details;

  AuditLog({
    required this.id,
    required this.action,
    required this.timestamp,
    required this.userName,
    required this.details,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userName: json['userName'] as String,
      details: json['details'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'userName': userName,
      'details': details,
    };
  }
}
