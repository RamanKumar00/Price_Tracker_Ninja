import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/color_constants.dart';
import '../models/product.dart';
import '../providers/providers.dart';

final predictionProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, productId) async {
  final api = ref.read(apiServiceProvider);
  return api.getPrediction(productId);
});

class PredictionWidget extends ConsumerWidget {
  final Product product;

  const PredictionWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(predictionProvider(product.id));

    return predictionAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: NinjaColors.violet),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Prediction unavailable: $e',
            style: const TextStyle(color: NinjaColors.rose)),
      ),
      data: (data) {
        if (data['predicted_price'] == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Not enough data to predict future prices.',
                style: TextStyle(color: NinjaColors.textSecondary, fontSize: 13)),
          );
        }

        final predicted = (data['predicted_price'] as num).toDouble();
        final confidence = (data['confidence_percent'] as num).toDouble();
        final current = product.currentPrice ?? 0.0;
        
        final isDropping = predicted < current;
        final color = isDropping ? NinjaColors.emerald : NinjaColors.amber;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NinjaColors.glassBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NinjaColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_graph_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('7-Day Forecast',
                            style: TextStyle(
                                fontSize: 12, color: NinjaColors.textMuted)),
                        const SizedBox(height: 4),
                        Text('₹${predicted.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: NinjaColors.textPrimary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: NinjaColors.violet.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${confidence.toStringAsFixed(0)}% Match',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: NinjaColors.violet)),
                      ),
                      const SizedBox(height: 6),
                      Text(isDropping ? 'Expected Drop' : 'Expected Rise',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: color)),
                    ],
                  )
                ],
              ),
              
              // New Stats section
              if ((product.startingPrice != null && product.currentPrice != null && product.startingPrice! > product.currentPrice!) ||
                  product.expiresAt != null) ...[
                Divider(height: 24, color: NinjaColors.border),
                
                if (product.startingPrice != null && product.currentPrice != null && product.startingPrice! > product.currentPrice!)
                  _statRow(
                    Icons.trending_down_rounded, 
                    'Dropped ₹${(product.startingPrice! - product.currentPrice!).toStringAsFixed(0)} (${(((product.startingPrice! - product.currentPrice!) / product.startingPrice!) * 100).toStringAsFixed(1)}%) since track started',
                    NinjaColors.emerald
                  ),
                
                if (product.expiresAt != null) ...[
                  if (product.startingPrice != null && product.currentPrice != null && product.startingPrice! > product.currentPrice!)
                    const SizedBox(height: 8),
                  
                  _expiryRow(product.expiresAt!),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ),
      ],
    );
  }

  Widget _expiryRow(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    final days = diff.inDays;
    final color = days < 3 ? NinjaColors.rose : NinjaColors.amber;
    
    String text = days < 0 ? 'Tracking Expired' : 'Tracking expires in $days ${days == 1 ? 'day' : 'days'}';
    
    return _statRow(Icons.timer_outlined, text, color);
  }
}
