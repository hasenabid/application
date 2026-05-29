enum ZoneStatus { ok, high, low, offline }

enum ZoneMode { auto, manual, standby }

const double kZoneMaxTemperature = 300.0;

class AuraZone {
  final String id;
  final String name;
  final double currentTemperature;
  final double setpointTemperature;
  final double maxTemperature;
  final ZoneStatus status;
  final ZoneMode mode;
  final int powerPercent;
  final bool isSSR;
  final bool isFu;
  final bool isR;
  final DateTime lastUpdated;

  const AuraZone({
    required this.id,
    required this.name,
    required this.currentTemperature,
    required this.setpointTemperature,
    this.maxTemperature = kZoneMaxTemperature,
    required this.status,
    required this.mode,
    required this.powerPercent,
    required this.isSSR,
    required this.isFu,
    required this.isR,
    required this.lastUpdated,
  });

  bool get isOk      => status == ZoneStatus.ok;
  bool get isHigh    => status == ZoneStatus.high;
  bool get isLow     => status == ZoneStatus.low;
  bool get isOffline => status == ZoneStatus.offline;

  factory AuraZone.fromJson(Map<String, dynamic> json) {
    return AuraZone(
      id:                  json['id'] as String,
      name:                json['name'] as String,
      currentTemperature:  (json['currentTemperature'] as num).toDouble(),
      setpointTemperature: (json['setpointTemperature'] as num).toDouble(),
      maxTemperature:      (json['maxTemperature'] as num?)?.toDouble() ?? kZoneMaxTemperature,
      status: ZoneStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ZoneStatus.offline,
      ),
      mode: ZoneMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => ZoneMode.manual,
      ),
      powerPercent: (json['powerPercent'] as num? ?? 0).toInt(),
      isSSR:        json['isSSR'] as bool? ?? false,
      isFu:         json['isFu']  as bool? ?? false,
      isR:          json['isR']   as bool? ?? false,
      lastUpdated:  DateTime.parse(json['lastUpdated'] as String),
    );
  }

  AuraZone copyWith({
    String? id,
    String? name,
    double? currentTemperature,
    double? setpointTemperature,
    double? maxTemperature,
    ZoneStatus? status,
    ZoneMode? mode,
    int? powerPercent,
    bool? isSSR,
    bool? isFu,
    bool? isR,
    DateTime? lastUpdated,
  }) {
    return AuraZone(
      id:                  id                  ?? this.id,
      name:                name                ?? this.name,
      currentTemperature:  currentTemperature  ?? this.currentTemperature,
      setpointTemperature: setpointTemperature ?? this.setpointTemperature,
      maxTemperature:      maxTemperature      ?? this.maxTemperature,
      status:              status              ?? this.status,
      mode:                mode                ?? this.mode,
      powerPercent:        powerPercent        ?? this.powerPercent,
      isSSR:               isSSR               ?? this.isSSR,
      isFu:                isFu                ?? this.isFu,
      isR:                 isR                 ?? this.isR,
      lastUpdated:         lastUpdated         ?? this.lastUpdated,
    );
  }
}

typedef AuraZoneStatus = ZoneStatus;
typedef AuraZoneMode   = ZoneMode;
