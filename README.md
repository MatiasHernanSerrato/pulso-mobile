# pulso_mobile

App movil de Pulso, armada con Flutter.

Pulso trackea peso (salud) y plata (gastos) en el mismo lugar, se conecta a balanzas inteligentes via BLE y manda los datos al backend (pulso-api).

## Correr el proyecto

```bash
flutter pub get
flutter run
```

Requiere Flutter 3.24 o mas nuevo. Ver `.metadata` para el revision exacto con el que se genero.

## Tests

```bash
flutter test
```

## Stack previsto

- Riverpod 2.5 para state management
- go_router para navegacion
- Drift para storage offline
- flutter_blue_plus para BLE (balanzas)
- HealthKit / Health Connect sync

Los repos hermanos son [pulso-api](https://github.com/MatiasHernanSerrato/pulso-api) y [pulso-web](https://github.com/MatiasHernanSerrato/pulso-web).

## BLE: balanzas inteligentes

Pulso lee peso directamente de balanzas BLE que implementen el perfil estandar **Weight Scale** (service UUID `0x181D`, characteristic `0x2A9D`), definido por la Bluetooth SIG.

El flujo es asi: la app pide permisos, escanea, el usuario toca la balanza en la lista, nos conectamos, descubrimos servicios y nos suscribimos a notifications de la char de peso. Cuando llega un paquete lo parseamos, convertimos a kg si vino en libras, y lo guardamos en el controller de weights.

Los archivos relevantes:

- `lib/features/ble/application/ble_permissions.dart` permisos por plataforma.
- `lib/features/ble/application/scan_controller.dart` scan + filtro por service UUID.
- `lib/features/ble/application/scale_connection.dart` conexion, discover services, reconexion automatica.
- `lib/features/ble/data/weight_measurement_parser.dart` parser del paquete 0x2A9D.
- `lib/features/ble/application/measurement_listener.dart` subscribe a notifications y guarda en db.

### Permisos

En Android 12+ pedimos `BLUETOOTH_SCAN` (con `neverForLocation`) y `BLUETOOTH_CONNECT`. En Android <= 11 cae a `BLUETOOTH`, `BLUETOOTH_ADMIN` y `ACCESS_FINE_LOCATION`, que es lo que pedia el stack viejo. En iOS declaramos `NSBluetoothAlwaysUsageDescription` y `bluetooth-central` en background modes.

### Limitaciones conocidas

Me parece importante escribir esto porque la mitad de las balanzas que se venden como "smart" hacen cosas raras.

- **Balanzas no-SIG**: muchas marcas chinas (Xiaomi Mi Scale v1, algunas Huawei) no implementan el perfil Weight Scale; usan un service vendor-specific. Por ahora las ignoramos. Si el advertisement NO incluye `0x181D`, la UI las muestra pero avisa que probablemente no sirvan.
- **% de grasa corporal**: lo manda el perfil `Body Composition` (`0x181B`), no lo parseamos todavia. Entra en la proxima iteracion.
- **Timestamps**: algunas balanzas prenden el flag de timestamp en el paquete y despues mandan basura en esos bytes (firmwares rotos). Si detectamos year 0 o mes fuera de rango, caemos a `DateTime.now()` y no perdemos la medicion.
- **Reconexion**: la mayoria de las balanzas se duermen a los 30 segundos de inactividad. Si durante ese tiempo cae la conexion probamos 4 reintentos con backoff (1s, 3s, 6s, 10s). Despues de eso pedimos al usuario que vuelva a tocar la balanza.
- **Multi-usuario**: las balanzas con perfiles multi-user mandan user id en el paquete, lo guardamos pero todavia no lo asociamos a usuarios de Pulso. Si vive mas de una persona en la casa, el que se para arriba gana.
- **iOS en background**: declaramos `bluetooth-central` pero no corremos listener en background sostenido todavia. El flujo asume que el usuario tiene la app abierta cuando se pesa.
- **Emuladores**: el BLE no funciona en el simulador de iOS y es poco confiable en los emuladores de Android. Para probar hace falta un device fisico.
