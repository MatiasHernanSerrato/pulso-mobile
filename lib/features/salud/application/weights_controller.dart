import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/weight_entry.dart';

/// Guarda la lista local de mediciones de peso. Por ahora in memory,
/// cuando conecte Drift lo cambio por una fuente real (y esto pasa a
/// ser un Stream).
///
/// La lista se mantiene ordenada de mas reciente a mas vieja porque
/// 99% de las vistas lo usan asi.
class WeightsController extends Notifier<List<WeightEntry>> {
  @override
  List<WeightEntry> build() => const [];

  void add(WeightEntry entry) {
    final next = [entry, ...state]
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    state = List.unmodifiable(next);
  }

  void remove(WeightEntry entry) {
    state = List.unmodifiable(state.where((e) => e != entry));
  }

  void replaceAll(Iterable<WeightEntry> entries) {
    final next = [...entries]
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    state = List.unmodifiable(next);
  }

  void clear() {
    state = const [];
  }
}

final weightsControllerProvider =
    NotifierProvider<WeightsController, List<WeightEntry>>(
  WeightsController.new,
);

/// Derivado: el ultimo peso registrado, o null si no hay nada.
/// Los widgets chicos de la pestana Hoy lo van a consumir.
final lastWeightProvider = Provider<WeightEntry?>((ref) {
  final list = ref.watch(weightsControllerProvider);
  return list.isEmpty ? null : list.first;
});

/// Derivado: promedio simple de los ultimos 7 dias. Si hay menos de 3
/// mediciones devolvemos null porque el promedio queda ruidoso.
final sevenDayAverageProvider = Provider<double?>((ref) {
  final list = ref.watch(weightsControllerProvider);
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final recent = list.where((e) => e.measuredAt.isAfter(cutoff)).toList();
  if (recent.length < 3) return null;
  final sum = recent.fold<double>(0, (acc, e) => acc + e.weightKg);
  return sum / recent.length;
});
