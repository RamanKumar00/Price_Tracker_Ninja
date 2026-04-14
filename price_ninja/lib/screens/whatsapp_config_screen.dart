import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/color_constants.dart';
import '../providers/providers.dart';
import '../widgets/neon_button.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';

class WhatsAppConfigScreen extends ConsumerStatefulWidget {
  const WhatsAppConfigScreen({super.key});

  @override
  ConsumerState<WhatsAppConfigScreen> createState() => _WhatsAppConfigScreenState();
}

class _WhatsAppConfigScreenState extends ConsumerState<WhatsAppConfigScreen> {
  String _completePhoneNumber = "";
  bool _isLoading = false;

  Future<void> _testAlert() async {
    if (_completePhoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Please enter a valid WhatsApp number'), backgroundColor: NinjaColors.rose),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final success = await api.sendTestAlert(
        alertType: 'whatsapp',
        whatsappNumber: _completePhoneNumber,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Test alert sent to $_completePhoneNumber!' : 'Failed to send alert.'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NinjaColors.background,
      appBar: AppBar(
        title: const Text('WhatsApp Integration', style: TextStyle(color: NinjaColors.textPrimary)),
        backgroundColor: NinjaColors.surface,
        elevation: 0,
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
                      const Icon(Icons.chat_bubble_outline_rounded, color: NinjaColors.emerald, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Twilio WhatsApp Sandbox',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'To receive WhatsApp alerts, you must first join the Twilio sandbox by sending "join [your-keyword]" to your Twilio number. Your credentials must also be set in the Railway console.',
                    style: TextStyle(fontSize: 14, color: NinjaColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your WhatsApp Number',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary),
            ),
            const SizedBox(height: 12),
            IntlPhoneField(
              decoration: InputDecoration(
                filled: true,
                fillColor: NinjaColors.surface,
                hintText: 'Phone Number',
                hintStyle: const TextStyle(color: NinjaColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: NinjaColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: NinjaColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: NinjaColors.emerald, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              initialCountryCode: 'IN', // Default to India
              dropdownTextStyle: const TextStyle(color: NinjaColors.textPrimary, fontSize: 16),
              style: const TextStyle(color: NinjaColors.textPrimary, fontSize: 16),
              onChanged: (phone) {
                setState(() {
                  _completePhoneNumber = phone.completeNumber;
                });
              },
              cursorColor: NinjaColors.emerald,
              pickerDialogStyle: PickerDialogStyle(
                backgroundColor: NinjaColors.surface,
                countryNameStyle: const TextStyle(color: NinjaColors.textPrimary),
                countryCodeStyle: const TextStyle(color: NinjaColors.textPrimary),
                searchFieldInputDecoration: InputDecoration(
                  hintText: 'Search Country',
                  hintStyle: const TextStyle(color: NinjaColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: NinjaColors.textMuted),
                ),
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
