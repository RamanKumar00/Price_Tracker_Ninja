import 'package:flutter/material.dart';
import '../config/color_constants.dart';

class TrendIndicator extends StatelessWidget {
  final double changePercent;
  final bool showBackground;

  const TrendIndicator({
    super.key,
    required this.changePercent,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    if (changePercent == 0.0) return const SizedBox.shrink();

    final isDown = changePercent < 0;
    final color = isDown ? NinjaColors.emerald : NinjaColors.rose;
    final icon = isDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final text = '${changePercent.abs().toStringAsFixed(1)}%';

    if (!showBackground) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
