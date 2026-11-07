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
