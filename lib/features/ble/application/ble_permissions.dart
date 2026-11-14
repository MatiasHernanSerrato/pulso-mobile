import 'dart:io' show Platform;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resultado de pedir permisos antes de arrancar un scan BLE.
/// Lo uso para decidir si abro la pagina de scan o si muestro una
/// pantalla con el motivo (y el boton de abrir settings cuando aplica).
enum BlePermissionStatus {
  /// Todo ok, se puede escanear y conectar.
  granted,

  /// El usuario dijo que no en el dialogo del sistema, pero puede volver
  /// a abrir la app y aceptar la proxima vez.
  denied,

  /// El usuario marco "no volver a preguntar" (o en iOS tiro reject
  /// una vez y ya queda asi hasta que entre a Ajustes). Hay que
  /// mandarlo a settings a mano.
  permanentlyDenied,

  /// Bluetooth esta apagado a nivel sistema. En Android podemos pedir
  /// que lo prendan, en iOS no (hay que avisarle al usuario).
  bluetoothOff,

  /// El device no tiene BLE (emuladores viejos, algun tablet). No hay
  /// mucho para hacer, solo esconder la feature.
  unsupported,
}

/// Envuelve lo poco de permisos que flutter_blue_plus expone y lo que
/// hay que pedir por plataforma. No uso permission_handler todavia
/// porque FBP ya hace la danza de BLUETOOTH_SCAN/CONNECT en Android 12+.
///
/// Nota: esto NO pide ACCESS_FINE_LOCATION en Android 12+. Ponemos
/// neverForLocation en el manifest para no tener que hacerlo.
class BlePermissions {
  const BlePermissions();

  Future<BlePermissionStatus> request() async {
    // La primera guarda: que el chipset soporte BLE.
    if (await FlutterBluePlus.isSupported == false) {
      return BlePermissionStatus.unsupported;
    }

    // En Android, si el adapter esta OFF podemos pedir prenderlo.
    // En iOS tiramos el estado y listo (iOS no nos deja prenderlo).
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState == BluetoothAdapterState.off) {
      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn();
          // Esperamos a que el OS nos confirme que arranco.
          await FlutterBluePlus.adapterState
              .where((s) => s == BluetoothAdapterState.on)
              .first
              .timeout(const Duration(seconds: 5));
        } on Exception {
          return BlePermissionStatus.bluetoothOff;
        }
      } else {
        return BlePermissionStatus.bluetoothOff;
      }
    }

    // En FBP 1.33, startScan y connect lanzan FlutterBluePlusException
    // si falta el permiso. Hacemos un scan de 0 segundos como probe
    // para forzar el prompt del sistema, y leemos el error.
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(milliseconds: 1),
      );
      await FlutterBluePlus.stopScan();
      return BlePermissionStatus.granted;
    } on FlutterBluePlusException catch (e) {
      // El code "unauthorized" cubre los dos casos de denied, no
      // distinguimos permanentlyDenied vs denied aca; lo infiere
      // la UI pidiendo dos veces seguidas.
      if (e.description != null &&
          e.description!.toLowerCase().contains('permission')) {
        return BlePermissionStatus.denied;
      }
      rethrow;
    }
  }
}

final blePermissionsProvider = Provider<BlePermissions>((ref) {
  return const BlePermissions();
});
