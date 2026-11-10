import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/weight_entry.dart';

/// Grafico de tendencia de peso. Pensado para la pestania Salud, usa
/// fl_chart con una sola serie (kg). Si hay menos de dos puntos devuelve
/// un placeholder porque dibujar una linea con un solo punto queda feo.
class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({
    super.key,
    required this.entries,
    this.windowDays = 30,
  });

  /// Lista completa de mediciones, en cualquier orden. El widget la
  /// filtra a los ultimos [windowDays] dias y la ordena por fecha.
  final List<WeightEntry> entries;

  /// Cuantos dias para atras consideramos. Default 30, la Salud vista
  /// larga va a pedir 180.
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();

    if (points.length < 2) {
      return _Empty(hasAny: points.isNotEmpty);
    }

    final cs = Theme.of(context).colorScheme;
    final minY = _niceFloor(points.map((p) => p.y).reduce(_min) - 0.5);
    final maxY = _niceCeil(points.map((p) => p.y).reduce(_max) + 0.5);

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 16, 8),
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: cs.outlineVariant.withOpacity(0.5),
                strokeWidth: 1,
                dashArray: const [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: (maxY - minY) / 4,
                  getTitlesWidget: (v, _) => Text(
                    v.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: _bottomInterval(points),
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= points.length) {
                      return const SizedBox.shrink();
                    }
                    final d = points[idx].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('d/M').format(d),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), points[i].y),
                ],
                isCurved: true,
                curveSmoothness: 0.25,
                preventCurveOverShooting: true,
                color: cs.primary,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: points.length <= 14,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 3,
                    color: cs.primary,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: cs.primary.withOpacity(0.08),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => cs.inverseSurface,
                getTooltipItems: (touched) => [
                  for (final t in touched)
                    LineTooltipItem(
                      '${t.y.toStringAsFixed(1)} kg\n'
                      '${DateFormat('EEE d MMM', 'es').format(points[t.x.toInt()].date)}',
                      TextStyle(color: cs.onInverseSurface, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_Point> _buildPoints() {
    final cutoff = DateTime.now().subtract(Duration(days: windowDays));
    final filtered = entries
        .where((e) => e.measuredAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    return filtered
        .map((e) => _Point(e.measuredAt, e.weightKg))
        .toList(growable: false);
  }

  double _bottomInterval(List<_Point> ps) {
    if (ps.length <= 6) return 1;
    return (ps.length / 5).ceilToDouble();
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasAny});
  final bool hasAny;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            hasAny
                ? 'Cargame al menos dos mediciones para ver la tendencia'
                : 'Todavia no hay mediciones',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      ),
    );
  }
}

class _Point {
  const _Point(this.date, this.y);
  final DateTime date;
  final double y;
}

double _min(double a, double b) => a < b ? a : b;
double _max(double a, double b) => a > b ? a : b;

// Redondeo a .5 para que la escala Y quede linda.
double _niceFloor(double v) => (v * 2).floorToDouble() / 2;
double _niceCeil(double v) => (v * 2).ceilToDouble() / 2;
