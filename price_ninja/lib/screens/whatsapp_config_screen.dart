import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/color_constants.dart';
import '../providers/providers.dart';
import '../widgets/glass_input.dart';
import '../widgets/neon_button.dart';

class WhatsAppConfigScreen extends ConsumerStatefulWidget {
  const WhatsAppConfigScreen({super.key});

  @override
  ConsumerState<WhatsAppConfigScreen> createState() => _WhatsAppConfigScreenState();
}

class _WhatsAppConfigScreenState extends ConsumerState<WhatsAppConfigScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _testAlert() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Please enter a WhatsApp number'), backgroundColor: NinjaColors.rose),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final success = await api.sendTestAlert(
        alertType: 'whatsapp',
        whatsappNumber: phone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Test alert sent to $phone!' : 'Failed to send alert.'),
            backgroundColor: success ? NinjaColors.emerald : NinjaColors.rose,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: NinjaColors.rose),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NinjaColors.background,
      appBar: AppBar(
        title: const Text('WhatsApp Integration', style: TextStyle(color: NinjaColors.textPrimary)),
        backgroundColor: NinjaColors.surface,
        iconTheme: const IconThemeData(color: NinjaColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NinjaColors.glassBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NinjaColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: NinjaColors.emerald, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Twilio WhatsApp Sandbox',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'To receive WhatsApp alerts, you must first join the Twilio sandbox from your WhatsApp account. Make sure your TWILIO_SID and TWILIO_AUTH_TOKEN are set in your backend .env file.',
                    style: TextStyle(fontSize: 14, color: NinjaColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Test Phone Number',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: NinjaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NinjaColors.border),
              ),
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: '+1234567890',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: NinjaColors.textPrimary),
              ),
            ),
            const SizedBox(height: 24),
            NeonButton(
              text: 'Send Test Alert',
              icon: Icons.send_rounded,
              colorIndex: 3, // emerald
              isLoading: _isLoading,
              onPressed: _testAlert,
            ),
          ],
        ),
      ),
    );
  }
}
