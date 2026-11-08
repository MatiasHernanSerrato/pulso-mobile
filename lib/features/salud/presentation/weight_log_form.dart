import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formulario para cargar un peso. Devuelve un [WeightEntry] con pop
/// si se guarda, o null si se cancela.
class WeightLogForm extends StatefulWidget {
  const WeightLogForm({super.key, this.initial});

  final WeightEntry? initial;

  @override
  State<WeightLogForm> createState() => _WeightLogFormState();
}

class _WeightLogFormState extends State<WeightLogForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kg;
  late final TextEditingController _fat;
  late final TextEditingController _note;
  late DateTime _measuredAt;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _kg = TextEditingController(text: i?.weightKg.toStringAsFixed(1) ?? '');
    _fat = TextEditingController(
      text: i?.bodyFat != null ? i!.bodyFat!.toStringAsFixed(1) : '',
    );
    _note = TextEditingController(text: i?.note ?? '');
    _measuredAt = i?.measuredAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _kg.dispose();
    _fat.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredAt),
    );
    if (t == null) return;
    setState(() {
      _measuredAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final kg = double.parse(_kg.text.replaceAll(',', '.'));
    final fatText = _fat.text.trim();
    final fat = fatText.isEmpty ? null : double.parse(fatText.replaceAll(',', '.'));
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();

    Navigator.of(context).pop(
      WeightEntry(
        weightKg: kg,
        bodyFat: fat,
        measuredAt: _measuredAt,
        note: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Cargar peso' : 'Editar peso'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _kg,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                suffixText: 'kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Falta el peso';
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed == null) return 'No parece un numero';
                if (parsed <= 0 || parsed >= 500) {
                  return 'Fuera de rango (0 a 500)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fat,
              decoration: const InputDecoration(
                labelText: 'Grasa corporal (opcional)',
                suffixText: '%',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed == null) return 'No parece un numero';
                if (parsed < 0 || parsed > 100) return 'Entre 0 y 100';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Momento de la medicion'),
              subtitle: Text(_formatDateTime(_measuredAt)),
              trailing: const Icon(Icons.edit),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'ej. despues de entrenar',
              ),
              maxLines: 3,
              maxLength: 280,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} $hh:$mm';
  }
}

/// Modelo local del form. Despues se mapea al tipo compartido cuando
/// arme el provider de weights.
class WeightEntry {
  const WeightEntry({
    required this.weightKg,
    required this.measuredAt,
    this.bodyFat,
    this.note,
  });

  final double weightKg;
  final double? bodyFat;
  final DateTime measuredAt;
  final String? note;
}
