import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_mobile/features/salud/application/weights_controller.dart';
import 'package:pulso_mobile/features/salud/domain/weight_entry.dart';

void main() {
  group('WeightsController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    WeightEntry mk(double kg, {DateTime? at}) => WeightEntry(
          weightKg: kg,
          measuredAt: at ?? DateTime.now(),
        );

    test('empieza vacio', () {
      expect(container.read(weightsControllerProvider), isEmpty);
    });

    test('add ordena de mas reciente a mas vieja', () {
      final ctrl = container.read(weightsControllerProvider.notifier);
      final now = DateTime(2026, 11, 10, 10);
      ctrl.add(mk(70, at: now.subtract(const Duration(days: 2))));
      ctrl.add(mk(71, at: now));
      ctrl.add(mk(70.5, at: now.subtract(const Duration(days: 1))));

      final list = container.read(weightsControllerProvider);
      expect(list.map((e) => e.weightKg), [71, 70.5, 70]);
    });

    test('lastWeightProvider refleja el mas reciente', () {
      final ctrl = container.read(weightsControllerProvider.notifier);
      ctrl.add(mk(72));
      expect(container.read(lastWeightProvider)?.weightKg, 72);
    });

    test('sevenDayAverage es null con menos de 3 mediciones', () {
      final ctrl = container.read(weightsControllerProvider.notifier);
      ctrl.add(mk(70));
      ctrl.add(mk(71));
      expect(container.read(sevenDayAverageProvider), isNull);
    });

    test('sevenDayAverage promedia bien', () {
      final ctrl = container.read(weightsControllerProvider.notifier);
      final now = DateTime.now();
      ctrl.add(mk(70, at: now));
      ctrl.add(mk(72, at: now.subtract(const Duration(days: 1))));
      ctrl.add(mk(71, at: now.subtract(const Duration(days: 2))));
      expect(container.read(sevenDayAverageProvider), closeTo(71, 0.001));
    });

    test('remove saca la entrada', () {
      final ctrl = container.read(weightsControllerProvider.notifier);
      final e = mk(80);
      ctrl.add(e);
      ctrl.remove(e);
      expect(container.read(weightsControllerProvider), isEmpty);
    });
  });
}
