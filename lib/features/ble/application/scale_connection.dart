import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/discovered_scale.dart';

/// UUIDs del perfil Weight Scale.
const String weightScaleServiceUuid =
    '0000181d-0000-1000-8000-00805f9b34fb';
const String weightMeasurementCharUuid =
    '00002a9d-0000-1000-8000-00805f9b34fb';

/// Service "Body Composition" tambien es relevante para balanzas que
/// reportan % de grasa. Lo leo pero no lo uso todavia en el parser.
const String bodyCompositionServiceUuid =
    '0000181b-0000-1000-8000-00805f9b34fb';

/// Estados posibles de la conexion con una balanza. Los uso para
/// pintar la UI de "Conectando..." / "Esperando medicion..." / etc.
enum ScaleConnectionPhase {
  idle,
  connecting,
  discovering,
  ready,

  /// Cayo la conexion pero estamos intentando restablecerla sin
  /// pedirle al usuario que vuelva a tocar nada. La UI muestra el
  /// nombre del device y un spinner chico.
  reconnecting,
  disconnected,
  error,
}

class ScaleConnectionState {
  const ScaleConnectionState({
    required this.phase,
    this.device,
    this.weightCharacteristic,
    this.message,
  });

  const ScaleConnectionState.idle() : this(phase: ScaleConnectionPhase.idle);

  final ScaleConnectionPhase phase;
  final DiscoveredScale? device;

  /// La char 0x2A9D una vez descubierta. La usa el parser para
  /// subscribirse a notifications.
  final BluetoothCharacteristic? weightCharacteristic;

  /// Mensaje humano para la UI cuando algo sale mal.
  final String? message;

  ScaleConnectionState copyWith({
    ScaleConnectionPhase? phase,
    DiscoveredScale? device,
    BluetoothCharacteristic? weightCharacteristic,
    String? message,
    bool clearMessage = false,
  }) {
    return ScaleConnectionState(
      phase: phase ?? this.phase,
      device: device ?? this.device,
      weightCharacteristic:
          weightCharacteristic ?? this.weightCharacteristic,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

/// Maneja conectar a UNA balanza a la vez. Multi conexion no la
/// soportamos todavia (nadie tiene dos balanzas, no vale la pena).
class ScaleConnectionController extends Notifier<ScaleConnectionState> {
  StreamSubscription<BluetoothConnectionState>? _connStateSub;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  /// Backoff: 1s, 3s, 6s, 10s, y despues damos por perdido. Las
  /// balanzas tipo Xiaomi se duermen a los ~30s de inactividad; si el
  /// usuario se bajo y volvio a subir, cualquiera de estos intentos la
  /// agarra. Despues de los 4 intentos el usuario tiene que iniciar
  /// la reconexion a mano (mostramos boton).
  static const List<Duration> _reconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 6),
    Duration(seconds: 10),
  ];

  @override
  ScaleConnectionState build() {
    ref.onDispose(() async {
      _reconnectTimer?.cancel();
      await _connStateSub?.cancel();
      final d = state.device;
      if (d != null) {
        try {
          await BluetoothDevice.fromId(d.id).disconnect();
        } on Exception {
          // best effort: puede estar ya desconectado.
        }
      }
    });
    return const ScaleConnectionState.idle();
  }

  Future<void> connect(DiscoveredScale target) async {
    // Si teniamos otra conexion viva, la cortamos primero.
    await _teardown();

    _reconnectAttempts = 0;
    state = state.copyWith(
      phase: ScaleConnectionPhase.connecting,
      device: target,
      clearMessage: true,
    );

    await _doConnect(target, isReconnect: false);
  }

  /// El loop interno: lo llaman connect() y el reconnect timer.
  Future<void> _doConnect(DiscoveredScale target,
      {required bool isReconnect}) async {
    final device = BluetoothDevice.fromId(target.id);

    // Escuchamos el estado para detectar drops. Importante: lo
    // cancelamos antes de re-suscribir, si no quedan listeners
    // apilados y double trigger del handler.
    await _connStateSub?.cancel();
    _connStateSub = device.connectionState.listen(_onConnStateChanged);

    try {
      // autoConnect:false porque queremos feedback rapido. Si la
      // balanza esta durmiendo ya le damos un "no apareció" al toque
      // en vez de colgar al usuario esperando.
      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 12),
      );
    } on Exception catch (e) {
      if (isReconnect) {
        _scheduleReconnect(target);
      } else {
        state = state.copyWith(
          phase: ScaleConnectionPhase.error,
          message: 'No pudimos conectar: $e',
        );
      }
      return;
    }

    state = state.copyWith(phase: ScaleConnectionPhase.discovering);

    final List<BluetoothService> services;
    try {
      services = await device.discoverServices();
    } on Exception catch (e) {
      state = state.copyWith(
        phase: ScaleConnectionPhase.error,
        message: 'Falló descubrir servicios: $e',
      );
      await device.disconnect();
      return;
    }

    final weightChar = _findWeightMeasurementChar(services);
    if (weightChar == null) {
      state = state.copyWith(
        phase: ScaleConnectionPhase.error,
        message: 'Esta balanza no expone el servicio Weight Scale.',
      );
      await device.disconnect();
      return;
    }

    _reconnectAttempts = 0;
    state = state.copyWith(
      phase: ScaleConnectionPhase.ready,
      weightCharacteristic: weightChar,
      clearMessage: true,
    );
  }

  /// Handler del stream de estado de BLE. Centraliza la logica de
  /// "se cayo -> reintento" para no duplicarla.
  void _onConnStateChanged(BluetoothConnectionState cs) {
    if (cs != BluetoothConnectionState.disconnected) return;

    final currentPhase = state.phase;
    // Si el usuario ya tiro disconnect() nosotros mismos pasamos a
    // idle, ahi no hacemos nada.
    if (currentPhase == ScaleConnectionPhase.idle) return;

    // Caso tipico: estabamos ready y la balanza se durmio. Intentamos
    // reconectar silenciosamente.
    final target = state.device;
    if (target == null) {
      state = state.copyWith(phase: ScaleConnectionPhase.disconnected);
      return;
    }

    state = state.copyWith(
      phase: ScaleConnectionPhase.reconnecting,
      message: 'La balanza se durmio, reintentando...',
    );
    _scheduleReconnect(target);
  }

  void _scheduleReconnect(DiscoveredScale target) {
    _reconnectTimer?.cancel();
    if (_reconnectAttempts >= _reconnectDelays.length) {
      state = state.copyWith(
        phase: ScaleConnectionPhase.disconnected,
        message: 'No pudimos reconectar. Tocá reintentar.',
      );
      return;
    }

    final delay = _reconnectDelays[_reconnectAttempts];
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () {
      // El usuario pudo haber cancelado entre medio.
      if (state.phase != ScaleConnectionPhase.reconnecting) return;
      _doConnect(target, isReconnect: true);
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _teardown();
    state = const ScaleConnectionState.idle();
  }

  Future<void> _teardown() async {
    _reconnectTimer?.cancel();
    final d = state.device;
    await _connStateSub?.cancel();
    _connStateSub = null;
    if (d != null) {
      try {
        await BluetoothDevice.fromId(d.id).disconnect();
      } on Exception {
        // ignoramos.
      }
    }
  }

  /// Busca la char 0x2A9D dentro del service 0x181D. Si no esta en el
  /// service estandar, hacemos un fallback ultra permisivo y buscamos
  /// la char por UUID en cualquier servicio (algunas balanzas custom
  /// la meten en un service vendor-specific).
  BluetoothCharacteristic? _findWeightMeasurementChar(
      List<BluetoothService> services) {
    final wsService = services
        .where((s) =>
            s.uuid.toString().toLowerCase() == weightScaleServiceUuid)
        .cast<BluetoothService?>()
        .firstOrNull;

    if (wsService != null) {
      for (final c in wsService.characteristics) {
        if (c.uuid.toString().toLowerCase() == weightMeasurementCharUuid) {
          return c;
        }
      }
    }

    // Fallback: buscar la char en cualquier servicio.
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.uuid.toString().toLowerCase() == weightMeasurementCharUuid) {
          return c;
        }
      }
    }
    return null;
  }
}

final scaleConnectionProvider = NotifierProvider<ScaleConnectionController,
    ScaleConnectionState>(ScaleConnectionController.new);

// Dart 3 ya tiene firstOrNull pero nuestro min sdk es 3.5, lo dejamos
// explicito para que no se queje si bajamos a 3.3 en algun fork.
extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
