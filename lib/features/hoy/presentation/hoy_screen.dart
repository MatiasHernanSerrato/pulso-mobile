import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/summary_card.dart';
import '../widgets/quick_action.dart';

class HoyScreen extends ConsumerWidget {
  const HoyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoy = _todayLabel();

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
                const SummaryCard(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Ultimo peso',
                  primary: 'sin datos',
                  secondary: 'cargalo manual o conecta la balanza',
                ),
                const SizedBox(height: 12),
                const SummaryCard(
                  icon: Icons.favorite_outline,
                  title: 'Promedio 7 dias',
                  primary: 'sin datos',
                  secondary: 'necesitamos al menos 3 mediciones',
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
}
