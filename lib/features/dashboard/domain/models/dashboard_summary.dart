enum SystemStatus { normal, warning, error, offline }

class DashboardSummary {
  final int activeZonesCount;
  final int totalZonesCount;
  final int activeAlertsCount;
  final SystemStatus systemStatus;

  const DashboardSummary({
    required this.activeZonesCount,
    required this.totalZonesCount,
    required this.activeAlertsCount,
    required this.systemStatus,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      activeZonesCount: json['activeZonesCount'] as int,
      totalZonesCount: json['totalZonesCount'] as int,
      activeAlertsCount: json['activeAlertsCount'] as int,
      systemStatus: SystemStatus.values.firstWhere(
        (e) => e.name == json['systemStatus'],
        orElse: () => SystemStatus.offline,
      ),
    );
  }
}
