import 'package:flutter/material.dart';

/// Tarjeta chica de resumen que usamos en Hoy. Tiene un icono a la izquierda
/// un titulo arriba, un valor primario grande y un subtitulo opcional.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.primary,
    this.secondary,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String primary;
  final String? secondary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.outline,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      primary,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (secondary != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondary!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.outline,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}
