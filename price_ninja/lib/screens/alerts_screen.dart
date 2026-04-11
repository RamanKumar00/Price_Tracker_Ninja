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
  final _emailController = TextEditingController();
  bool _sendingTestEmail = false;

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
                      const Text('Alerts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: NinjaColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Configure notifications', style: TextStyle(fontSize: 14, color: NinjaColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            _section(title: 'Email Alerts', icon: Icons.mail_outline_rounded, color: NinjaColors.violet, children: [
              GlassInput(controller: _emailController, hintText: 'your@email.com', labelText: 'Email Address', prefixIcon: Icons.alternate_email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              NeonButton(text: 'Send Test Email', icon: Icons.send_rounded, isLoading: _sendingTestEmail, outlined: true, colorIndex: 0, onPressed: _sendTestEmail),
            ]),
            const SizedBox(height: 16),

            _section(title: 'WhatsApp Alerts', icon: Icons.chat_outlined, color: NinjaColors.emerald, children: [
              Text('Configure Twilio credentials in the backend .env file to enable WhatsApp alerts.', style: TextStyle(fontSize: 13, color: NinjaColors.textSecondary, height: 1.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: NinjaColors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: NinjaColors.blue.withValues(alpha: 0.15))),
                child: Row(children: [
                  Icon(Icons.info_outline, color: NinjaColors.blue, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Requires Twilio account + WhatsApp sandbox', style: TextStyle(fontSize: 12, color: NinjaColors.blue))),
                ]),
              ),
            ]),
            const SizedBox(height: 28),

            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: NinjaColors.violet, shape: BoxShape.circle, boxShadow: [BoxShadow(color: NinjaColors.violet.withValues(alpha: 0.5), blurRadius: 6)])),
              const SizedBox(width: 10),
              Text('Alert History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary)),
            ]),
            const SizedBox(height: 14),

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

  Widget _section({required String title, required IconData icon, required Color color, required List<Widget> children}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: NinjaColors.glassBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: NinjaColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary)),
        ]),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Future<void> _sendTestEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: NinjaColors.surface, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text('Enter an email first', style: TextStyle(color: NinjaColors.amber))));
      return;
    }
    setState(() => _sendingTestEmail = true);
    try {
      final api = ref.read(apiServiceProvider);
      final success = await api.sendTestAlert(alertType: 'email', emailAddress: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: NinjaColors.surface, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(success ? 'Test email sent!' : 'Failed to send', style: TextStyle(color: success ? NinjaColors.emerald : NinjaColors.rose))));
      }
      ref.invalidate(alertHistoryProvider);
    } finally { setState(() => _sendingTestEmail = false); }
  }

  @override
  void dispose() { _emailController.dispose(); super.dispose(); }
}
