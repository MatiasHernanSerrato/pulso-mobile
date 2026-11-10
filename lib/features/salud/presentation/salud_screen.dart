import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/weights_controller.dart';
import '../domain/weight_entry.dart';
import '../widgets/weight_trend_chart.dart';
import 'weight_log_form.dart';

class SaludScreen extends ConsumerWidget {
  const SaludScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<WeightEntry>(
      MaterialPageRoute(builder: (_) => const WeightLogForm()),
    );
    if (result == null) return;
    ref.read(weightsControllerProvider.notifier).add(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peso guardado (local)')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(weightsControllerProvider);
    final avg = ref.watch(sevenDayAverageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Salud')),
      body: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aca vamos a mostrar peso, grasa corporal y tendencia. Tocame el +.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tendencia (30 dias)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (avg != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Promedio 7d: ${avg.toStringAsFixed(1)} kg',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                            ),
                          ),
                        WeightTrendChart(entries: entries),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final e in entries) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.monitor_weight_outlined),
                      title: Text('${e.weightKg.toStringAsFixed(1)} kg'),
                      subtitle: Text([
                        '${e.measuredAt.day}/${e.measuredAt.month}',
                        if (e.bodyFat != null)
                          '${e.bodyFat!.toStringAsFixed(1)}%',
                        if (e.note != null) e.note!,
                      ].join(' . ')),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(weightsControllerProvider.notifier)
                            .remove(e),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Cargar peso'),
      ),
    );
  }
}
