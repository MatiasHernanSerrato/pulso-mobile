import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_mobile/features/ble/data/weight_measurement_parser.dart';

void main() {
  const parser = WeightMeasurementParser();

  group('WeightMeasurementParser - SI', () {
    test('peso simple sin flags', () {
      // flags=0x00 -> SI, sin timestamp ni nada extra
      // raw peso = 14470 -> 14470 * 0.005 = 72.35 kg
      final bytes = [0x00, 0x86, 0x38];
      final m = parser.parse(bytes);
      expect(m.weightKg, closeTo(72.35, 0.001));
      expect(m.measuredAt, isNull);
      expect(m.userId, isNull);
      expect(m.bmi, isNull);
      expect(m.unitsImperial, isFalse);
    });

    test('peso con timestamp', () {
      // flags=0x02 -> SI + timestamp
      // peso raw 14000 = 70.0 kg
      // ts: year 2026, month 11, day 14, 15:44:00
      final bytes = <int>[
        0x02, // flags
        0xB0, 0x36, // weight 14000 LE
        0xEA, 0x07, 11, 14, 15, 44, 0, // 0x07EA = 2026
      ];
      final m = parser.parse(bytes);
      expect(m.weightKg, closeTo(70.0, 0.001));
      expect(m.measuredAt, DateTime(2026, 11, 14, 15, 44, 0));
    });

    test('peso con todo el payload', () {
      // flags=0x0E -> SI + ts + user + bmi
      // peso raw 15000 = 75.00 kg
      // ts 2026-01-02 03:04:05
      // user 7
      // bmi raw 234 = 23.4
      // height raw 1780 = 1.780 m
      final bytes = <int>[
        0x0E,
        0x98, 0x3A, // 15000 LE
        0xEA, 0x07, 1, 2, 3, 4, 5,
        7,
        0xEA, 0x00, // 234
        0xF4, 0x06, // 1780
      ];
      final m = parser.parse(bytes);
      expect(m.weightKg, closeTo(75.0, 0.001));
      expect(m.measuredAt, DateTime(2026, 1, 2, 3, 4, 5));
      expect(m.userId, 7);
      expect(m.bmi, closeTo(23.4, 0.001));
      expect(m.heightMeters, closeTo(1.780, 0.001));
    });

    test('user id 0 vuelve como null (guest)', () {
      // flags=0x04 -> user id, sin nada mas
      final bytes = <int>[0x04, 0x86, 0x38, 0];
      final m = parser.parse(bytes);
      expect(m.userId, isNull);
    });
  });

  group('WeightMeasurementParser - Imperial', () {
    test('peso en libras se convierte a kg', () {
      // flags=0x01 -> Imperial
      // raw = 15950 -> 159.50 lb -> 72.3459 kg
      final bytes = [0x01, 0x4E, 0x3E];
      final m = parser.parse(bytes);
      expect(m.unitsImperial, isTrue);
      expect(m.weightKg, closeTo(72.3459, 0.001));
    });
  });

  group('WeightMeasurementParser - errores', () {
    test('paquete muy corto tira excepcion', () {
      expect(
        () => parser.parse([0x00, 0x01]),
        throwsA(isA<WeightMeasurementParseException>()),
      );
    });

    test('peso 0xFFFF marcado como invalido', () {
      final bytes = [0x00, 0xFF, 0xFF];
      expect(
        () => parser.parse(bytes),
        throwsA(isA<WeightMeasurementParseException>()),
      );
    });

    test('flag de timestamp prendido pero bytes faltan: devuelve sin ts',
        () {
      // flags=0x02 pero solo dos bytes mas
      final bytes = [0x02, 0x86, 0x38, 0xEA, 0x07];
      final m = parser.parse(bytes);
      expect(m.weightKg, closeTo(72.35, 0.001));
      expect(m.measuredAt, isNull);
    });

    test('year 0 en timestamp cae a null', () {
      final bytes = <int>[
        0x02,
        0x86, 0x38,
        0, 0, 11, 14, 15, 44, 0, // year 0
      ];
      final m = parser.parse(bytes);
      expect(m.measuredAt, isNull);
    });

    test('mes invalido en timestamp cae a null', () {
      final bytes = <int>[
        0x02,
        0x86, 0x38,
        0xEA, 0x07, 13, 14, 15, 44, 0, // mes 13
      ];
      final m = parser.parse(bytes);
      expect(m.measuredAt, isNull);
    });
  });
}
