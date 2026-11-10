import 'package:flutter/material.dart';

import '../widgets/weight_trend_chart.dart';
import 'weight_log_form.dart';

class SaludScreen extends StatefulWidget {
  const SaludScreen({super.key});

  @override
  State<SaludScreen> createState() => _SaludScreenState();
}

class _SaludScreenState extends State<SaludScreen> {
  final List<WeightEntry> _entries = [];

  Future<void> _openForm() async {
    final result = await Navigator.of(context).push<WeightEntry>(
      MaterialPageRoute(builder: (_) => const WeightLogForm()),
    );
    if (result == null) return;
    setState(() => _entries.insert(0, result));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Peso guardado (local)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [..._entries]
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Salud')),
      body: _entries.isEmpty
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
                        WeightTrendChart(entries: _entries),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final e in sorted) ...[
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
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Cargar peso'),
      ),
    );
  }
}
