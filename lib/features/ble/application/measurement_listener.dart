import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../salud/application/weights_controller.dart';
import '../../salud/domain/weight_entry.dart';
import '../data/weight_measurement_parser.dart';
import 'scale_connection.dart';

/// Estado del listener de mediciones. [lastReading] se usa en la UI
/// para mostrar "ultimo peso: 72.35 kg" en vivo mientras estas parado
/// arriba de la balanza.
class MeasurementStreamState {
  const MeasurementStreamState({
    required this.listening,
    this.lastReading,
    this.lastSavedAt,
    this.error,
  });

  const MeasurementStreamState.idle()
      : listening = false,
        lastReading = null,
        lastSavedAt = null,
        error = null;

  final bool listening;
  final WeightMeasurement? lastReading;
  final DateTime? lastSavedAt;
  final String? error;
}

/// Subscribe a notifications de la char 0x2A9D y mete cada medicion
/// parseada en el WeightsController.
///
/// Dedup: algunas balanzas (las que no tienen RTC) mandan el mismo
/// paquete varias veces por segundo. Guardamos el ultimo peso + ts y
/// descartamos reads duplicados dentro de 2 segundos.
class MeasurementListener extends Notifier<MeasurementStreamState> {
  StreamSubscription<List<int>>? _sub;
  static const _parser = WeightMeasurementParser();

  @override
  MeasurementStreamState build() {
    // Cuando la conexion cambia a ready, arrancamos solos. Cuando se
    // cae, paramos. Asi la UI no tiene que acordarse de llamar start.
    ref.listen<ScaleConnectionState>(scaleConnectionProvider, (prev, next) {
      if (next.phase == ScaleConnectionPhase.ready &&
          next.weightCharacteristic != null) {
        _attach(next.weightCharacteristic!);
      } else if (next.phase == ScaleConnectionPhase.disconnected ||
          next.phase == ScaleConnectionPhase.idle ||
          next.phase == ScaleConnectionPhase.error) {
        _detach();
      }
    });

    ref.onDispose(_detach);
    return const MeasurementStreamState.idle();
  }

  Future<void> _attach(BluetoothCharacteristic char) async {
    await _detach();
    try {
      await char.setNotifyValue(true);
    } on Exception catch (e) {
      state = MeasurementStreamState(
        listening: false,
        error: 'No pudimos subscribirnos a mediciones: $e',
      );
      return;
    }

    _sub = char.lastValueStream.listen(_onPacket);
    state = const MeasurementStreamState(listening: true);
  }

  Future<void> _detach() async {
    await _sub?.cancel();
    _sub = null;
    if (state.listening) {
      state = MeasurementStreamState(
        listening: false,
        lastReading: state.lastReading,
        lastSavedAt: state.lastSavedAt,
      );
    }
  }

  void _onPacket(List<int> bytes) {
    if (bytes.isEmpty) return;

    final WeightMeasurement parsed;
    try {
      parsed = _parser.parse(bytes);
    } on WeightMeasurementParseException catch (e) {
      state = MeasurementStreamState(
        listening: state.listening,
        lastReading: state.lastReading,
        lastSavedAt: state.lastSavedAt,
        error: e.message,
      );
      return;
    }

    // Dedup: mismo peso dentro de 2s = balanza que todavia no se
    // estabilizo, solo updateamos la "ultima lectura" pero no guardamos
    // de nuevo.
    final now = DateTime.now();
    final prev = state.lastReading;
    final prevSaved = state.lastSavedAt;
    final isDupe = prev != null &&
        prevSaved != null &&
        (parsed.weightKg - prev.weightKg).abs() < 0.05 &&
        now.difference(prevSaved) < const Duration(seconds: 2);

    if (isDupe) {
      state = MeasurementStreamState(
        listening: state.listening,
        lastReading: parsed,
        lastSavedAt: prevSaved,
      );
      return;
    }

    final entry = WeightEntry(
      weightKg: _round(parsed.weightKg, 2),
      measuredAt: parsed.measuredAt ?? now,
      bodyFat: null, // todavia no leemos body composition, viene en otra char
      note: 'Balanza BLE',
    );
    ref.read(weightsControllerProvider.notifier).add(entry);

    state = MeasurementStreamState(
      listening: state.listening,
      lastReading: parsed,
      lastSavedAt: now,
    );
  }

  double _round(double v, int decimals) {
    final factor = _pow10(decimals);
    return (v * factor).round() / factor;
  }

  double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}

final measurementListenerProvider =
    NotifierProvider<MeasurementListener, MeasurementStreamState>(
  MeasurementListener.new,
);
