import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/discovered_scale.dart';

/// UUID oficial del Weight Scale Service (bluetooth-sig assigned numbers).
/// Las balanzas compatibles lo advierten en su scan response.
const String weightScaleServiceUuid = '0000181d-0000-1000-8000-00805f9b34fb';

/// Estado del scan. Lo exponemos como notifier porque la UI quiere
/// saber si estamos escaneando (para prender el loader) y la lista.
class ScanState {
  const ScanState({
    required this.scanning,
    required this.devices,
    this.error,
  });

  const ScanState.idle()
      : scanning = false,
        devices = const [],
        error = null;

  final bool scanning;
  final List<DiscoveredScale> devices;
  final String? error;

  ScanState copyWith({
    bool? scanning,
    List<DiscoveredScale>? devices,
    String? error,
    bool clearError = false,
  }) {
    return ScanState(
      scanning: scanning ?? this.scanning,
      devices: devices ?? this.devices,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Maneja el ciclo scan -> lista -> stop. El timeout por defecto es
/// corto (8s) porque despues de unos segundos ya aparecieron todos los
/// devices cercanos y seguir scaneando solo quema bateria.
class ScanController extends Notifier<ScanState> {
  StreamSubscription<List<ScanResult>>? _sub;
  StreamSubscription<bool>? _isScanningSub;

  @override
  ScanState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _isScanningSub?.cancel();
      // Si quedamos scaneando al disposar, mejor cortarlo.
      FlutterBluePlus.stopScan();
    });
    return const ScanState.idle();
  }

  /// Arranca un scan nuevo. Si ya habia uno, lo reemplaza.
  Future<void> start({
    Duration timeout = const Duration(seconds: 8),
    bool onlyWeightScales = false,
  }) async {
    await stop();
    state = state.copyWith(scanning: true, devices: [], clearError: true);

    // Nos subscribimos ANTES de startScan por si algun advertisement
    // llega enseguida.
    _sub = FlutterBluePlus.scanResults.listen((results) {
      final next = <DiscoveredScale>[];
      for (final r in results) {
        final advertisesWs = r.advertisementData.serviceUuids
            .map((u) => u.toString().toLowerCase())
            .any((u) => u == weightScaleServiceUuid);

        if (onlyWeightScales && !advertisesWs) continue;

        next.add(DiscoveredScale(
          id: r.device.remoteId.toString(),
          name: r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : r.device.platformName,
          rssi: r.rssi,
          advertisedAt: DateTime.now(),
          advertisesWeightScaleService: advertisesWs,
        ));
      }
      // Ordeno por RSSI (mas cerca primero). Las que advierten el
      // service de peso van arriba igual.
      next.sort((a, b) {
        if (a.advertisesWeightScaleService !=
            b.advertisesWeightScaleService) {
          return a.advertisesWeightScaleService ? -1 : 1;
        }
        return b.rssi.compareTo(a.rssi);
      });
      state = state.copyWith(devices: next);
    });

    _isScanningSub = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!isScanning && state.scanning) {
        state = state.copyWith(scanning: false);
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: onlyWeightScales
            ? [Guid(weightScaleServiceUuid)]
            : const [],
      );
    } on Exception catch (e) {
      state = state.copyWith(
        scanning: false,
        error: 'No pudimos arrancar el scan: $e',
      );
    }
  }

  Future<void> stop() async {
    await FlutterBluePlus.stopScan();
    await _sub?.cancel();
    _sub = null;
    await _isScanningSub?.cancel();
    _isScanningSub = null;
    if (state.scanning) {
      state = state.copyWith(scanning: false);
    }
  }
}

final scanControllerProvider =
    NotifierProvider<ScanController, ScanState>(ScanController.new);
