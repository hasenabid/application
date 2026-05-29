// This file is a purely Dart model — no freezed/codegen needed here.
// We replace the old freezed model with a simple class for flexibility.

enum ZoneStatus { ok, high, low, offline }
enum ZoneMode { auto, manual, standby }

class ThermoplayZone {
  final String id;
  final String name;
  final double currentTemperature;
  final double setpointTemperature;
  final ZoneStatus status;
  final ZoneMode mode;
  final int powerPercent; // e.g. 16 = 16%
  final bool isSSR;
  final bool isFu;
  final bool isR;
  final DateTime lastUpdated;

  const ThermoplayZone({
    required this.id,
    required this.name,
    required this.currentTemperature,
    required this.setpointTemperature,
    required this.status,
    required this.mode,
    required this.powerPercent,
    required this.isSSR,
    required this.isFu,
    required this.isR,
    required this.lastUpdated,
  });

  bool get isOk => status == ZoneStatus.ok;
  bool get isHigh => status == ZoneStatus.high;
  bool get isLow => status == ZoneStatus.low;
  bool get isOffline => status == ZoneStatus.offline;

  factory ThermoplayZone.fromJson(Map<String, dynamic> json) {
    return ThermoplayZone(
      id: json['id'] as String,
      name: json['name'] as String,
      currentTemperature: (json['currentTemperature'] as num).toDouble(),
      setpointTemperature: (json['setpointTemperature'] as num).toDouble(),
      status: ZoneStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ZoneStatus.offline,
      ),
      mode: ZoneMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => ZoneMode.manual,
      ),
      powerPercent: (json['powerPercent'] as num? ?? 0).toInt(),
      isSSR: json['isSSR'] as bool? ?? false,
      isFu: json['isFu'] as bool? ?? false,
      isR: json['isR'] as bool? ?? false,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  ThermoplayZone copyWith({
    String? id,
    String? name,
    double? currentTemperature,
    double? setpointTemperature,
    ZoneStatus? status,
    ZoneMode? mode,
    int? powerPercent,
    bool? isSSR,
    bool? isFu,
    bool? isR,
    DateTime? lastUpdated,
  }) {
    return ThermoplayZone(
      id: id ?? this.id,
      name: name ?? this.name,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      setpointTemperature: setpointTemperature ?? this.setpointTemperature,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      powerPercent: powerPercent ?? this.powerPercent,
      isSSR: isSSR ?? this.isSSR,
      isFu: isFu ?? this.isFu,
      isR: isR ?? this.isR,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Keep old enums as aliases for backward compatibility in other files
typedef ThermoplayZoneStatus = ZoneStatus;
typedef ThermoplayZoneMode = ZoneMode;
