import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/color_constants.dart';
import '../providers/providers.dart';
import '../widgets/neon_button.dart';
import '../widgets/glass_input.dart';

/// Premium Alerts screen.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  Widget build(BuildContext context) {
    final alertHistoryAsync = ref.watch(alertHistoryProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: NinjaColors.glassBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NinjaColors.border),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 22, color: NinjaColors.textPrimary),
                    onPressed: () => ref.read(bottomNavIndexProvider.notifier).state = 0,
                    tooltip: 'Back to Dashboard',
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alert History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: NinjaColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('View your past price drop alerts', style: TextStyle(fontSize: 14, color: NinjaColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Removed Email and WhatsApp configuration sections



            alertHistoryAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: NinjaColors.violet, strokeWidth: 2))),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: NinjaColors.rose.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: NinjaColors.rose.withValues(alpha: 0.15))),
                child: Text('Could not load history.\n$err', style: const TextStyle(color: NinjaColors.textMuted, fontSize: 13)),
              ),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(28), width: double.infinity,
                    decoration: BoxDecoration(color: NinjaColors.glassBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: NinjaColors.border)),
                    child: Column(children: [
                      Icon(Icons.notifications_none_rounded, size: 36, color: NinjaColors.textMuted),
                      const SizedBox(height: 12),
                      Text('No alerts sent yet', style: TextStyle(color: NinjaColors.textMuted, fontSize: 14)),
                    ]),
                  );
                }
                return Column(children: alerts.asMap().entries.map((e) {
                  final a = e.value; final i = e.key;
                  final accent = NinjaColors.accentAt(i);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: NinjaColors.glassBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: NinjaColors.border)),
                    child: Row(children: [
                      Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(a.alertType == 'email' ? Icons.mail_outline_rounded : Icons.chat_outlined, color: accent, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text('₹${a.price.toStringAsFixed(0)} • ${DateFormat('dd MMM, HH:mm').format(a.sentAt)}', style: TextStyle(fontSize: 11, color: NinjaColors.textMuted)),
                      ])),
                      Icon(a.success ? Icons.check_circle_outline : Icons.error_outline, size: 18, color: a.success ? NinjaColors.emerald : NinjaColors.rose),
                    ]),
                  );
                }).toList());
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

}
