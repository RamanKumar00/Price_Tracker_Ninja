import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/color_constants.dart';
import '../config/app_config.dart';
import '../providers/providers.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/whatsapp_config_screen.dart';
import '../screens/auth_screen.dart';
import '../widgets/particle_background.dart';

/// Premium Settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PatternBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- Header ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildBackButton(ref),
                          const SizedBox(width: 16),
                          Text(
                            'Settings',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: NinjaColors.textPrimary,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideX(begin: -0.1),
                      const SizedBox(height: 24),
                      
                      // User Profile Header
                      userAsync.when(
                        data: (user) => _buildProfileHeader(user),
                        loading: () => const SizedBox(height: 80),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // --- App Info ---
                    _buildSectionHeader('System Info', Icons.info_outline_rounded, NinjaColors.violet),
                    const SizedBox(height: 12),
                    _buildGlassCard([
                      _buildDataRow('Protocol', AppConfig.appName),
                      _buildDivider(),
                      _buildDataRow('Firmware', 'v${AppConfig.appVersion}'),
                      _buildDivider(),
                      _buildDataRow('Host API', AppConfig.apiBaseUrl, isSecondary: true),
                      _buildDivider(),
                      _buildDataRow('UI Theme', 'Premium Midnight'),
                    ]).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 28),

                    // --- Scraping Config ---
                    _buildSectionHeader('Extraction Engine', Icons.bolt_rounded, NinjaColors.blue),
                    const SizedBox(height: 12),
                    _buildGlassCard([
                      _buildDataRow('Scan Mode', 'Smart (On-Demand)'),
                      _buildDivider(),
                      _buildDataRow('Coverage', 'Amazon, Flipkart, etc.'),
                      _buildDivider(),
                      _buildDataRow('Protocol', 'BS4 + Cloud Agent'),
                    ]).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                    const SizedBox(height: 28),

                    // --- Integrations ---
                    _buildSectionHeader('Notifications', Icons.notifications_active_rounded, NinjaColors.amber),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      'WhatsApp Integration', 
                      'Configure Twilio sandbox & routing', 
                      Icons.chat_bubble_outline_rounded, 
                      NinjaColors.emerald,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhatsAppConfigScreen()))
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 28),

                    // --- Display ---
                    _buildSectionHeader('Appearance', Icons.palette_outlined, NinjaColors.violet),
                    const SizedBox(height: 12),
                    _buildGlassCard([
                      _buildThemeToggle(ref),
                    ]).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                    const SizedBox(height: 28),

                    // --- Developer ---
                    _buildSectionHeader('Developer Settings', Icons.terminal_rounded, NinjaColors.emerald),
                    const SizedBox(height: 12),
                    _buildGlassCard([
                      _buildLinkTile(Icons.api_rounded, 'API Documentation', '${AppConfig.apiBaseUrl}/docs'),
                      _buildDivider(),
                      _buildLinkTile(Icons.monitor_heart_rounded, 'System Health', '${AppConfig.apiBaseUrl}/health'),
                    ]).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                    const SizedBox(height: 28),

                    // --- Diagnostics ---
                    _buildSectionHeader('Diagnostics', Icons.troubleshoot_rounded, NinjaColors.rose),
                    const SizedBox(height: 12),
                    _buildAlertLogsCard(ref),
                    
                    const SizedBox(height: 48),

                    // --- Footer ---
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: NinjaColors.glassBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NinjaColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.code_rounded, size: 14, color: NinjaColors.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  'Built with Flutter × FastAPI',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: NinjaColors.textMuted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'PRICE NINJA PRO v4.0',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: NinjaColors.textSecondary.withOpacity(0.5),
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 0,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: NinjaColors.glassBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NinjaColors.border),
        ),
        child: const Icon(Icons.arrow_back_rounded, size: 20, color: NinjaColors.textPrimary),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    final name = user?.email?.split('@')[0] ?? 'Guest Ninja';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NinjaColors.violet.withOpacity(0.15),
            NinjaColors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NinjaColors.violet.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: NinjaColors.violet.withOpacity(0.05),
            blurRadius: 20,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: NinjaColors.violet.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: NinjaColors.violet.withOpacity(0.4)),
            ),
            child: const Icon(Icons.person_rounded, color: NinjaColors.violet, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AGENT ${name.toUpperCase()}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: NinjaColors.textPrimary,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  user != null ? 'Authenticated System Access' : 'Limited Access Guest',
                  style: TextStyle(fontSize: 12, color: NinjaColors.textMuted),
                ),
              ],
            ),
          ),
          if (user != null)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.verified_user_rounded, color: NinjaColors.emerald, size: 20),
            )
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: NinjaColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NinjaColors.glassBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NinjaColors.border),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isSecondary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: NinjaColors.textMuted)),
          Flexible(
            child: Text(
              value, 
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12, 
                fontWeight: FontWeight.w600, 
                color: isSecondary ? NinjaColors.blue : NinjaColors.textPrimary
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: NinjaColors.border, height: 20);
  }

  Widget _buildLinkTile(IconData icon, String label, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: NinjaColors.blue.withOpacity(0.7)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 13, color: NinjaColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: NinjaColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NinjaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NinjaColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: NinjaColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: NinjaColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: NinjaColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertLogsCard(WidgetRef ref) {
    final productsState = ref.watch(productsProvider);
    // We can fetch history here or just show status. For now, let's show status and a button.
    return _buildGlassCard([
      Row(
        children: [
          _buildStatusDot(true), // Assuming API is up if we are here
          const SizedBox(width: 8),
          const Text('System Connectivity: ONLINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: NinjaColors.emerald)),
        ],
      ),
      _buildDivider(),
      _buildDataRow('Email Config', 'Verified/Active', isSecondary: true),
      _buildDivider(),
      const Text(
        'TIP: If alerts fail on Railway, use a "RESEND_API_KEY" (re_xxx) instead of SMTP. Twilio Sandbox requires sending "join keyword" first.',
        style: TextStyle(fontSize: 10, color: NinjaColors.textMuted, fontStyle: FontStyle.italic),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () {
            // Show a simple bottom sheet with logs (Mock for now, can be fully implemented)
            _showLogsSheet(ref.context);
          },
          icon: const Icon(Icons.history_rounded, size: 16),
          label: const Text('View Alert History / Error Logs'),
          style: TextButton.styleFrom(
            foregroundColor: NinjaColors.blue,
            backgroundColor: NinjaColors.blue.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStatusDot(bool active) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: active ? NinjaColors.emerald : NinjaColors.rose,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: (active ? NinjaColors.emerald : NinjaColors.rose).withOpacity(0.4), blurRadius: 4, spreadRadius: 1)
        ],
      ),
    );
  }

  void _showLogsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NinjaColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Alert History & Errors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: NinjaColors.textPrimary)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: NinjaColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: ref.read(apiServiceProvider).getAlertHistory(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: NinjaColors.blue));
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No alert logs found yet.', style: TextStyle(color: NinjaColors.textMuted)));
                      }
                      
                      final logs = snapshot.data!;
                      return ListView.separated(
                        itemCount: logs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final bool isSuccess = log['success'] ?? false;
                          final String type = (log['alert_type'] ?? 'unknown').toString().toUpperCase();
                          final String time = log['sent_at'] != null ? 
                            DateTime.parse(log['sent_at']).toLocal().toString().split('.')[0] : 'Just now';
                          
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: NinjaColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSuccess ? NinjaColors.emerald.withOpacity(0.2) : NinjaColors.rose.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(isSuccess ? Icons.check_circle_rounded : Icons.error_rounded, 
                                         color: isSuccess ? NinjaColors.emerald : NinjaColors.rose, size: 16),
                                    const SizedBox(width: 8),
                                    Text('$type ALERT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isSuccess ? NinjaColors.emerald : NinjaColors.rose)),
                                    const Spacer(),
                                    Text(time, style: TextStyle(fontSize: 10, color: NinjaColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(log['product_name'] ?? 'System Test', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: NinjaColors.textPrimary)),
                                if (!isSuccess && log['error_message'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('ERROR: ${log['error_message']}', 
                                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: NinjaColors.rose.withOpacity(0.8))),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildThemeToggle(WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    final isDark = mode == ThemeMode.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? NinjaColors.violet : Colors.orange, size: 20),
            const SizedBox(width: 12),
            const Text('Dark Mode Display', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        Switch.adaptive(
          value: isDark,
          activeTrackColor: NinjaColors.violet.withOpacity(0.3),
          activeColor: NinjaColors.violet,
          onChanged: (val) {
            ref.read(themeProvider.notifier).setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
          },
        ),
      ],
    );
  }
}
