import 'dart:typed_data';

/// Parser del Weight Measurement Characteristic (UUID 0x2A9D) del
/// perfil Weight Scale (service 0x181D), tal como lo define el
/// documento "Weight Scale Service" 1.0 de la Bluetooth SIG.
///
/// Layout del paquete:
///
///   byte 0        flags
///     bit 0       0 = SI (kg, res 0.005), 1 = Imperial (lb, res 0.01)
///     bit 1       1 = incluye timestamp (7 bytes, formato DateTime)
///     bit 2       1 = incluye User ID (1 byte)
///     bit 3       1 = incluye BMI + altura (4 bytes en SI, idem imperial)
///     bits 4-7    reservados (los ignoramos)
///   byte 1..2     weight, uint16 little endian
///   byte 3..9     timestamp (si flag bit 1)
///                   year  uint16 LE
///                   month uint8
///                   day   uint8
///                   hour  uint8
///                   min   uint8
///                   sec   uint8
///   byte x        user id (si flag bit 2)
///   byte x..x+3   bmi uint16 + height uint16 (si flag bit 3)
///
/// Resolucion:
///   SI       peso en unidades de 5 g, i.e. kg = raw * 0.005
///   Imp.     peso en unidades de 0.01 lb, i.e. lb = raw * 0.01
///   BMI      unidades de 0.1
///   Altura   unidades de 0.001 m (SI) o 0.1 in (imp)
///
/// Casos borde que ya me cruce:
///   - Algunas balanzas chinas mandan el paquete sin timestamp y con el
///     flag bit 1 en 1 igual. Validamos la longitud para no leer basura.
///   - Si el peso es 0xFFFF significa "not valid" (per spec). Tiramos
///     [WeightMeasurementParseException] para que el caller descarte.
class WeightMeasurement {
  const WeightMeasurement({
    required this.weightKg,
    this.measuredAt,
    this.userId,
    this.bmi,
    this.heightMeters,
    required this.unitsImperial,
  });

  /// Siempre en kg en el modelo, aunque la balanza mande libras. La
  /// conversion la hace el parser (1 lb = 0.45359237 kg).
  final double weightKg;

  /// Timestamp que mando la balanza, o null si no vino. Cuando null,
  /// el caller usa DateTime.now() como fallback.
  final DateTime? measuredAt;

  /// Algunos modelos tienen perfiles multi usuario (1..255). 0 es
  /// "guest", lo tratamos como null.
  final int? userId;

  /// BMI calculado por la balanza. Lo guardamos aparte porque nuestro
  /// modelo WeightEntry no tiene campo, lo agregamos despues.
  final double? bmi;
  final double? heightMeters;

  /// Flag original del paquete, por si en la UI queremos mostrar en
  /// que unidad reporto el device.
  final bool unitsImperial;
}

class WeightMeasurementParseException implements Exception {
  WeightMeasurementParseException(this.message);
  final String message;
  @override
  String toString() => 'WeightMeasurementParseException: $message';
}

class WeightMeasurementParser {
  const WeightMeasurementParser();

  WeightMeasurement parse(List<int> bytes) {
    if (bytes.length < 3) {
      throw WeightMeasurementParseException(
        'Paquete demasiado corto: ${bytes.length} bytes',
      );
    }

    final data = Uint8List.fromList(bytes);
    final bd = ByteData.sublistView(data);

    final flags = data[0];
    final imperial = (flags & 0x01) != 0;
    final hasTs = (flags & 0x02) != 0;
    final hasUser = (flags & 0x04) != 0;
    final hasBmi = (flags & 0x08) != 0;

    final rawWeight = bd.getUint16(1, Endian.little);
    if (rawWeight == 0xFFFF) {
      throw WeightMeasurementParseException('Peso marcado invalido');
    }

    double weightKg;
    if (imperial) {
      final lb = rawWeight * 0.01;
      weightKg = lb * 0.45359237;
    } else {
      weightKg = rawWeight * 0.005;
    }

    int offset = 3;

    DateTime? measuredAt;
    if (hasTs) {
      if (data.length < offset + 7) {
        // Firmware roto: flag prendido, bytes faltan. Devolvemos el
        // peso sin timestamp en vez de tirar excepcion para no
        // perder la medicion.
        return WeightMeasurement(
          weightKg: weightKg,
          measuredAt: null,
          unitsImperial: imperial,
        );
      }
      final year = bd.getUint16(offset, Endian.little);
      final month = data[offset + 2];
      final day = data[offset + 3];
      final hour = data[offset + 4];
      final minute = data[offset + 5];
      final second = data[offset + 6];
      offset += 7;
      // Si el year es 0 la spec dice "unknown date". No armamos
      // DateTime invalido.
      if (year != 0 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        measuredAt = DateTime(year, month, day, hour, minute, second);
      }
    }

    int? userId;
    if (hasUser && data.length > offset) {
      final u = data[offset];
      offset += 1;
      userId = u == 0 ? null : u;
    }

    double? bmi;
    double? heightMeters;
    if (hasBmi && data.length >= offset + 4) {
      final rawBmi = bd.getUint16(offset, Endian.little);
      final rawHeight = bd.getUint16(offset + 2, Endian.little);
      offset += 4;
      bmi = rawBmi * 0.1;
      if (imperial) {
        // Spec: altura en 0.1 inch. La pasamos a metros.
        heightMeters = (rawHeight * 0.1) * 0.0254;
      } else {
        heightMeters = rawHeight * 0.001;
      }
    }

    return WeightMeasurement(
      weightKg: weightKg,
      measuredAt: measuredAt,
      userId: userId,
      bmi: bmi,
      heightMeters: heightMeters,
      unitsImperial: imperial,
    );
  }
}
