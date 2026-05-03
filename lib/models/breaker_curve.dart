class BreakerCurve {
  final String id; // Format: hãng_dòng_type
  final String brand;
  final String series;
  final String type;
  final List<CurvePoint> points;

  BreakerCurve({
    required this.id,
    required this.brand,
    required this.series,
    required this.type,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'series': series,
        'type': type,
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory BreakerCurve.fromJson(Map<String, dynamic> json) {
    return BreakerCurve(
      id: json['id'] ?? '${json['brand']}_${json['series']}_${json['type']}',
      brand: json['brand'] ?? '',
      series: json['series'] ?? '',
      type: json['type'] ?? '',
      points: (json['points'] as List)
          .map((p) => CurvePoint.fromJson(p))
          .toList(),
    );
  }
}

class CurvePoint {
  final double k;
  final double tMin;
  final double tMax;

  CurvePoint({required this.k, required this.tMin, required this.tMax});

  Map<String, dynamic> toJson() => {
        'k': k,
        't_min': tMin,
        't_max': tMax,
      };

  factory CurvePoint.fromJson(Map<String, dynamic> json) {
    return CurvePoint(
      k: (json['k'] as num).toDouble(),
      tMin: (json['t_min'] as num).toDouble(),
      tMax: (json['t_max'] as num).toDouble(),
    );
  }
}
