/// Modelo de dominio para una medicion de peso. Lo saque del form
/// (ahi vivia porque arranque rapido) para poder compartirlo con el
/// provider y con el grafico.
///
/// Por ahora es un value object a mano; cuando saque el backend real
/// lo voy a pasar a freezed + json_serializable.
class WeightEntry {
  const WeightEntry({
    required this.weightKg,
    required this.measuredAt,
    this.id,
    this.bodyFat,
    this.note,
  });

  /// Id local (uuid del cliente) o id del servidor cuando sincroniza.
  /// null para los que acabamos de crear y no sincronizaron todavia.
  final String? id;
  final double weightKg;
  final double? bodyFat;
  final DateTime measuredAt;
  final String? note;

  WeightEntry copyWith({
    String? id,
    double? weightKg,
    double? bodyFat,
    DateTime? measuredAt,
    String? note,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      weightKg: weightKg ?? this.weightKg,
      bodyFat: bodyFat ?? this.bodyFat,
      measuredAt: measuredAt ?? this.measuredAt,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightEntry &&
        other.id == id &&
        other.weightKg == weightKg &&
        other.bodyFat == bodyFat &&
        other.measuredAt == measuredAt &&
        other.note == note;
  }

  @override
  int get hashCode =>
      Object.hash(id, weightKg, bodyFat, measuredAt, note);
}
