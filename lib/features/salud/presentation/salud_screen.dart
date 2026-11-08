import 'package:flutter/material.dart';

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
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final e = _entries[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.monitor_weight_outlined),
                    title: Text('${e.weightKg.toStringAsFixed(1)} kg'),
                    subtitle: Text([
                      '${e.measuredAt.day}/${e.measuredAt.month}',
                      if (e.bodyFat != null) '${e.bodyFat!.toStringAsFixed(1)}%',
                      if (e.note != null) e.note!,
                    ].join(' · ')),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Cargar peso'),
      ),
    );
  }
}
