import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../salud/application/weights_controller.dart';
import '../widgets/summary_card.dart';
import '../widgets/quick_action.dart';

class HoyScreen extends ConsumerWidget {
  const HoyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoy = _todayLabel();
    final last = ref.watch(lastWeightProvider);
    final avg = ref.watch(sevenDayAverageProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('Hoy'),
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  hoy,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 16),
                SummaryCard(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Ultimo peso',
                  primary: last != null
                      ? '${last.weightKg.toStringAsFixed(1)} kg'
                      : 'sin datos',
                  secondary: last != null
                      ? _relativeDate(last.measuredAt)
                      : 'cargalo manual o conecta la balanza',
                ),
                const SizedBox(height: 12),
                SummaryCard(
                  icon: Icons.favorite_outline,
                  title: 'Promedio 7 dias',
                  primary:
                      avg != null ? '${avg.toStringAsFixed(1)} kg' : 'sin datos',
                  secondary: avg != null
                      ? 'calculado sobre las ultimas mediciones'
                      : 'necesitamos al menos 3 mediciones',
                ),
                const SizedBox(height: 12),
                const SummaryCard(
                  icon: Icons.payments_outlined,
                  title: 'Gastos del dia',
                  primary: r'$0',
                  secondary: 'ningun movimiento todavia',
                ),
                const SizedBox(height: 24),
                Text(
                  'Acciones rapidas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: QuickAction(
                        icon: Icons.add_chart,
                        label: 'Cargar peso',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: QuickAction(
                        icon: Icons.receipt_long,
                        label: 'Agregar gasto',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${now.day} de ${meses[now.month - 1]}';
  }

  String _relativeDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inHours < 1) return 'hace un rato';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 2) return 'ayer';
    return 'hace ${diff.inDays} dias';
  }
}
