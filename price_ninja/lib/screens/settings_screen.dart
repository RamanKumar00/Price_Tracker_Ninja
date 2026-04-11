import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/color_constants.dart';
import '../config/app_config.dart';
import '../providers/providers.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/whatsapp_config_screen.dart';
import '../screens/auth_screen.dart';

/// Premium Settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: NinjaColors.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 28),

            _section('About', Icons.info_outline, NinjaColors.violet, [
              _row('App', AppConfig.appName),
              _row('Version', 'v${AppConfig.appVersion}'),
              _row('Backend', AppConfig.apiBaseUrl),
              _row('Design', 'Premium Midnight'),
            ]),
            const SizedBox(height: 16),

            _section('Scraping', Icons.search_rounded, NinjaColors.blue, [
              _row('Mode', 'Manual (on-demand)'),
              _row('Platforms', 'Amazon.in, Flipkart'),
              _row('Engine', 'Selenium + BeautifulSoup'),
            ]),
            const SizedBox(height: 16),

            _section('Setup Guide', Icons.menu_book_rounded, NinjaColors.emerald, [
              _step('1', 'Start backend: uvicorn main:app --reload'),
              _step('2', 'Configure .env with Gmail App Password'),
              _step('3', 'Add product URL from Amazon/Flipkart'),
              _step('4', 'Click "Scrape All Prices" to fetch data'),
              _step('5', 'Set target price for automatic email alerts'),
            ]),
            const SizedBox(height: 16),

            _section('Alert Integrations', Icons.notifications_active_rounded, NinjaColors.amber, [
              _actionCard('WhatsApp Setup', 'Configure Twilio WhatsApp sandbox and send test alerts', Icons.chat_bubble_outline_rounded, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WhatsAppConfigScreen()));
              }),
            ]),
            const SizedBox(height: 16),

            _section('Display', Icons.palette_outlined, NinjaColors.violet, [
              _themeToggle(ref),
            ]),
            const SizedBox(height: 16),

            _section('Links', Icons.link_rounded, NinjaColors.amber, [
              _link(Icons.description_outlined, 'API Docs', '${AppConfig.apiBaseUrl}/docs'),
              _link(Icons.monitor_heart_outlined, 'Health Check', '${AppConfig.apiBaseUrl}/health'),
            ]),

            const SizedBox(height: 16),
            _section('Account', Icons.person_rounded, NinjaColors.rose, [
              Consumer(builder: (context, ref, _) {
                final user = ref.watch(authStateProvider).value;
                if (user == null) {
                  return _actionCard('Sign In', 'Authorize to sync results across devices', Icons.login_rounded, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
                  });
                }
                return _actionCard('Sign Out', 'Log out of Firebase Authentication', Icons.logout_rounded, () async {
                  await ref.read(authServiceProvider).signOut();
                });
              }),
            ]),

            const SizedBox(height: 40),
            Center(
              child: Column(children: [
                const Text('Price Ninja v4.0', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Flutter × Python FastAPI', style: TextStyle(fontSize: 12, color: NinjaColors.textMuted)),
              ]),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: NinjaColors.glassBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: NinjaColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary)),
        ]),
        Divider(color: NinjaColors.border, height: 24),
        ...children,
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: NinjaColors.textMuted)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: NinjaColors.textPrimary), textAlign: TextAlign.end)),
      ],
    ));
  }

  Widget _step(String num, String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 24, height: 24,
        decoration: BoxDecoration(color: NinjaColors.violet.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Center(child: Text(num, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NinjaColors.violet))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: NinjaColors.textSecondary, height: 1.4))),
    ]));
  }

  Widget _link(IconData icon, String label, String url) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
        Icon(icon, color: NinjaColors.blue, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13, color: NinjaColors.textPrimary)),
        const Spacer(),
        Icon(Icons.open_in_new_rounded, color: NinjaColors.textMuted, size: 14),
      ])),
    ));
  }

  Widget _themeToggle(WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    final isDark = mode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? NinjaColors.violet : Colors.orange, size: 20),
              const SizedBox(width: 12),
              const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          Switch.adaptive(
            value: isDark,
            activeColor: NinjaColors.violet,
            onChanged: (val) {
              ref.read(themeProvider.notifier).setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NinjaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NinjaColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: NinjaColors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: NinjaColors.textSecondary)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: NinjaColors.textMuted, size: 14),
        ]),
      ),
    ));
  }
}
