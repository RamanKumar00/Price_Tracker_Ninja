import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../config/color_constants.dart';

/// Premium price chart — smooth violet gradient line, clean glass container.
class PriceChart extends StatefulWidget {
  final List<Map<String, dynamic>> trendData;
  final String productName;

  const PriceChart({
    super.key,
    required this.trendData,
    required this.productName,
  });

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trendData.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: NinjaColors.glassBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NinjaColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart_rounded,
                  size: 40, color: NinjaColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No price data yet\nAdd a product and scrape',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: NinjaColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    final prices = <double>[];
    for (int i = 0; i < widget.trendData.length; i++) {
      final price = (widget.trendData[i]['price'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), price));
      prices.add(price);
    }

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final range = maxPrice - minPrice;
    final yMin = (minPrice - range * 0.1).clamp(0.0, double.infinity);
    final yMax = maxPrice + range * 0.1;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return Container(
          height: 280,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: NinjaColors.glassBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NinjaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: NinjaColors.violet,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: NinjaColors.violet.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.productName,
                        style: const TextStyle(
                          color: NinjaColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: yMin,
                    maxY: yMax,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: range > 0 ? range / 4 : 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withValues(alpha: 0.04),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 55,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '₹${_formatShort(value)}',
                              style: const TextStyle(
                                color: NinjaColors.textMuted,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: (spots.length / 5).ceilToDouble().clamp(1.0, 100.0),
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= widget.trendData.length) {
                              return const SizedBox.shrink();
                            }
                            final ts = widget.trendData[idx]['timestamp'] ?? '';
                            final dt = DateTime.tryParse(ts.toString());
                            if (dt == null) return const SizedBox.shrink();
                            return Text(
                              DateFormat('d/M').format(dt),
                              style: const TextStyle(
                                color: NinjaColors.textMuted,
                                fontSize: 9,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots
                            .map((s) => FlSpot(
                                  s.x,
                                  s.y * _animController.value,
                                ))
                            .toList(),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        gradient: LinearGradient(
                          colors: [
                            NinjaColors.violet,
                            NinjaColors.blue,
                          ],
                        ),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            final isTouch = index == _touchedIndex;
                            return FlDotCirclePainter(
                              radius: isTouch ? 6 : 3,
                              color: isTouch
                                  ? NinjaColors.violet
                                  : NinjaColors.blue,
                              strokeWidth: isTouch ? 2 : 0,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              NinjaColors.violet.withValues(alpha: 0.15),
                              NinjaColors.blue.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchCallback: (event, response) {
                        if (response?.lineBarSpots != null &&
                            response!.lineBarSpots!.isNotEmpty) {
                          setState(() {
                            _touchedIndex =
                                response.lineBarSpots!.first.spotIndex;
                          });
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) =>
                            NinjaColors.surface.withValues(alpha: 0.95),
                        tooltipRoundedRadius: 12,
                        tooltipBorder: BorderSide(
                          color: NinjaColors.border,
                        ),
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            final idx = spot.spotIndex;
                            final ts = widget.trendData[idx]['timestamp'] ?? '';
                            final dt = DateTime.tryParse(ts.toString());
                            final dateStr = dt != null
                                ? DateFormat('dd MMM, HH:mm').format(dt)
                                : '';
                            return LineTooltipItem(
                              '₹${spot.y.toStringAsFixed(0)}\n$dateStr',
                              const TextStyle(
                                color: NinjaColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 300),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatShort(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}
