import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../config/color_constants.dart';
import '../models/product.dart';
import '../providers/providers.dart';
import '../widgets/particle_background.dart';
import '../widgets/price_chart.dart';
import '../widgets/prediction_widget.dart';
import '../widgets/trend_indicator.dart';
import '../widgets/neon_button.dart';

/// Full-page product detail screen — shows product image, pricing matrix,
/// specs, chart & prediction in a scrollable Premium Midnight layout.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isScraping = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PatternBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Hero App Bar with Product Image ───
            _buildSliverAppBar(p, isDark),

            // ─── Body Content ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Product Name & Platform
                    _buildNameSection(p),
                    const SizedBox(height: 24),

                    // ─── Pricing Matrix ───
                    _buildPricingMatrix(p),
                    const SizedBox(height: 24),

                    // ─── Description ───
                    if (p.description != null && p.description!.isNotEmpty) ...[
                      _buildSectionHeader('Description', Icons.notes_rounded, NinjaColors.emerald),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          p.description!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: NinjaColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.05),
                      const SizedBox(height: 24),
                    ],

                    // ─── Quick Actions ───
                    _buildQuickActions(p),
                    const SizedBox(height: 28),

                    // ─── Price Trend Chart ───
                    _buildSectionHeader(
                        'Price History', Icons.show_chart_rounded, NinjaColors.blue),
                    const SizedBox(height: 12),
                    _buildChartSection(p),
                    const SizedBox(height: 24),

                    // ─── AI Prediction ───
                    _buildSectionHeader(
                        'AI Prediction', Icons.auto_awesome_rounded, NinjaColors.amber),
                    const SizedBox(height: 12),
                    PredictionWidget(product: p),
                    const SizedBox(height: 24),

                    // ─── Product Details/Specs ───
                    _buildSectionHeader(
                        'Product Details', Icons.info_outline_rounded, NinjaColors.emerald),
                    const SizedBox(height: 12),
                    _buildProductDetails(p),
                    const SizedBox(height: 24),

                    // ─── Stats Grid ───
                    _buildSectionHeader(
                        'Price Statistics', Icons.analytics_outlined, NinjaColors.violet),
                    const SizedBox(height: 12),
                    _buildStatsGrid(p),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── Sliver App Bar with Hero Image ───────────
  Widget _buildSliverAppBar(Product p, bool isDark) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? NinjaColors.background : Colors.white,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? NinjaColors.surface : Colors.white).withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? NinjaColors.border : const Color(0xFFE5E7EB),
            ),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? NinjaColors.textPrimary : const Color(0xFF1F2937),
            size: 20,
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => _toggleFavorite(p),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? NinjaColors.surface : Colors.white).withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? NinjaColors.border : const Color(0xFFE5E7EB),
              ),
            ),
            child: Icon(
              p.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: p.isFavorite ? NinjaColors.amber : NinjaColors.textMuted,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Product Image
            if (p.imageUrl != null && p.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: p.imageUrl!,
                fit: BoxFit.contain,
                placeholder: (_, __) => Container(
                  color: isDark ? NinjaColors.surface : const Color(0xFFF3F4F6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: NinjaColors.violet,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _buildImagePlaceholder(isDark),
              )
            else
              _buildImagePlaceholder(isDark),

            // Bottom gradient fade
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      (isDark ? NinjaColors.background : Colors.white).withValues(alpha: 0.8),
                      isDark ? NinjaColors.background : Colors.white,
                    ],
                  ),
                ),
              ),
            ),

            // Target Hit Badge
            if (p.isPriceBelowTarget)
              Positioned(
                top: 60,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: NinjaColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NinjaColors.emerald.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: NinjaColors.emerald.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: NinjaColors.emerald, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'TARGET HIT!',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: NinjaColors.emerald,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────── Product Name & Platform ───────────
  Widget _buildNameSection(Product p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: NinjaColors.violet.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NinjaColors.violet.withValues(alpha: 0.2)),
          ),
          child: Text(
            p.platform.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: NinjaColors.violet,
              letterSpacing: 1.2,
            ),
          ),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 12),

        // Product Name
        Text(
          p.name,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.3,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),

        // Change indicator + last checked
        Row(
          children: [
            if (p.changePercent != null) ...[
              TrendIndicator(changePercent: p.changePercent!),
              const SizedBox(width: 12),
            ],
            Icon(Icons.auto_graph_rounded,
                size: 14, color: NinjaColors.blue.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(
              p.lastChecked != null
                  ? 'Updated ${_timeAgo(p.lastChecked!)}'
                  : 'Awaiting first sweep...',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: NinjaColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  // ─────────── Pricing Matrix (Actual / Average / Target) ───────────
  Widget _buildPricingMatrix(Product p) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = 0.05 + _glowController.value * 0.1;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                NinjaColors.violet.withValues(alpha: 0.08),
                NinjaColors.blue.withValues(alpha: 0.05),
                NinjaColors.emerald.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NinjaColors.violet.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: NinjaColors.violet.withValues(alpha: glow),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Main price row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceColumn(
                    'ACTUAL PRICE',
                    p.currentPrice,
                    NinjaColors.textPrimary,
                    Icons.payments_rounded,
                    isMain: true,
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: NinjaColors.border,
                  ),
                  _buildPriceColumn(
                    'AVERAGE',
                    p.averagePrice,
                    NinjaColors.blue,
                    Icons.analytics_rounded,
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: NinjaColors.border,
                  ),
                  _buildPriceColumn(
                    'YOUR TARGET',
                    p.targetPrice > 0 ? p.targetPrice : null,
                    NinjaColors.emerald,
                    Icons.gps_fixed_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Savings indicator
              if (p.currentPrice != null && p.targetPrice > 0)
                _buildSavingsIndicator(p),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildPriceColumn(
    String label,
    double? value,
    Color color,
    IconData icon, {
    bool isMain = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: NinjaColors.textMuted,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value != null ? '₹${value.toStringAsFixed(0)}' : '---',
            style: GoogleFonts.jetBrainsMono(
              fontSize: isMain ? 24 : 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsIndicator(Product p) {
    final diff = p.currentPrice! - p.targetPrice;
    final isBelow = diff <= 0;
    final color = isBelow ? NinjaColors.emerald : NinjaColors.amber;
    final text = isBelow
        ? '🎯 ₹${diff.abs().toStringAsFixed(0)} below target!'
        : '⏳ ₹${diff.toStringAsFixed(0)} above target';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBelow ? Icons.check_circle_rounded : Icons.timer_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── Quick Actions ───────────
  Widget _buildQuickActions(Product p) {
    return Row(
      children: [
        Expanded(
          child: NeonButton(
            text: _isScraping ? 'Scraping...' : 'Refresh Price',
            icon: Icons.refresh_rounded,
            isLoading: _isScraping,
            colorIndex: 0,
            onPressed: () => _scrapeProduct(p),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NeonButton(
            text: 'Visit Store',
            icon: Icons.open_in_new_rounded,
            colorIndex: 1,
            onPressed: () => _openUrl(p.url),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  // ─────────── Section Header ───────────
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: NinjaColors.textPrimary,
            letterSpacing: 1.0,
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, color: color.withValues(alpha: 0.2)),
      ],
    ).animate().fadeIn().slideX(begin: -0.05);
  }

  // ─────────── Chart Section ───────────
  Widget _buildChartSection(Product p) {
    final trendAsync = ref.watch(priceTrendProvider(p.id));
    return trendAsync.when(
      loading: () => Container(
        height: 240,
        decoration: BoxDecoration(
          color: NinjaColors.glassBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NinjaColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: NinjaColors.violet,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (_, __) => PriceChart(trendData: const [], productName: p.name),
      data: (trend) => PriceChart(trendData: trend, productName: p.name),
    );
  }

  // ─────────── Product Details ───────────
  Widget _buildProductDetails(Product p) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          _detailRow(Icons.label_rounded, 'Product Name', p.name, NinjaColors.violet),
          _divider(),
          _detailRow(Icons.store_rounded, 'Platform', p.platform, NinjaColors.blue),
          _divider(),
          _detailRow(Icons.link_rounded, 'URL', _truncateUrl(p.url), NinjaColors.emerald),
          _divider(),
          _detailRow(
            Icons.calendar_today_rounded,
            'Tracking Since',
            dateFormat.format(p.createdAt),
            NinjaColors.amber,
          ),
          _divider(),
          _detailRow(
            Icons.update_rounded,
            'Last Updated',
            dateFormat.format(p.updatedAt),
            NinjaColors.rose,
          ),
          if (p.lastChecked != null) ...[
            _divider(),
            _detailRow(
              Icons.schedule_rounded,
              'Last Price Check',
              dateFormat.format(p.lastChecked!),
              NinjaColors.blue,
            ),
          ],
          _divider(),
          _detailRow(
            Icons.repeat_rounded,
            'Total Checks',
            '${p.totalChecks} times',
            NinjaColors.violet,
          ),
          if (p.expiresAt != null) ...[
            _divider(),
            _detailRow(
              Icons.timer_off_rounded,
              'Tracking Expires',
              dateFormat.format(p.expiresAt!),
              NinjaColors.rose,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NinjaColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
      height: 1,
    );
  }

  // ─────────── Stats Grid ───────────
  Widget _buildStatsGrid(Product p) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard('Lowest Price',
            p.lowestPrice != null ? '₹${p.lowestPrice!.toStringAsFixed(0)}' : 'N/A',
            Icons.trending_down_rounded, NinjaColors.emerald, 'All-time low'),
        _statCard('Highest Price',
            p.highestPrice != null ? '₹${p.highestPrice!.toStringAsFixed(0)}' : 'N/A',
            Icons.trending_up_rounded, NinjaColors.rose, 'Peak recorded'),
        _statCard('Starting Price',
            p.startingPrice != null ? '₹${p.startingPrice!.toStringAsFixed(0)}' : 'N/A',
            Icons.flag_rounded, NinjaColors.amber, 'When first tracked'),
        _statCard('Price Range',
            p.lowestPrice != null && p.highestPrice != null
                ? '₹${(p.highestPrice! - p.lowestPrice!).toStringAsFixed(0)}'
                : 'N/A',
            Icons.swap_vert_rounded, NinjaColors.blue, 'High − Low'),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _statCard(String label, String value, IconData icon, Color color, String subtitle) {
    final w = (MediaQuery.of(context).size.width - 32 - 12) / 2 - 1;
    return SizedBox(
      width: w,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NinjaColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: NinjaColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── Helpers ───────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _truncateUrl(String url) {
    if (url.length > 60) return '${url.substring(0, 60)}...';
    return url;
  }

  void _toggleFavorite(Product p) {
    ref.read(productsProvider.notifier).toggleFavorite(p.id, !p.isFavorite);
  }

  Future<void> _scrapeProduct(Product p) async {
    setState(() => _isScraping = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.scrapeProduct(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: NinjaColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text(
            '✅ Price refreshed successfully!',
            style: TextStyle(color: NinjaColors.emerald, fontWeight: FontWeight.w500),
          ),
        ));
      }
      // Reload products to get updated data
      ref.read(productsProvider.notifier).loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: NinjaColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Scrape failed: $e',
            style: const TextStyle(color: NinjaColors.rose, fontWeight: FontWeight.w500),
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _isScraping = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  
  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? NinjaColors.surface : const Color(0xFFF3F4F6),
        gradient: RadialGradient(
          colors: [
            NinjaColors.violet.withValues(alpha: 0.15),
            isDark ? NinjaColors.surface : const Color(0xFFF3F4F6),
          ],
          radius: 0.8,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shopping_bag_rounded,
            size: 100,
            color: NinjaColors.violet.withValues(alpha: 0.2),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1.5.seconds),
          if (isDark)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 140),
                Text(
                  'Awaiting Data...',
                  style: GoogleFonts.jetBrainsMono(
                    color: NinjaColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ]
            ),
        ],
      ),
    );
  }
}

