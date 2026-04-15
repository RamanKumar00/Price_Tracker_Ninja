import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/color_constants.dart';
import '../models/product.dart';
import '../models/platform_info.dart';
import '../providers/providers.dart';
import '../providers/search_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_input.dart';
import '../widgets/animated_title.dart';
import '../widgets/metric_card.dart';
import '../widgets/price_chart.dart';
import '../widgets/prediction_widget.dart';
import '../widgets/product_card.dart';
import '../widgets/neon_button.dart';
import '../widgets/particle_background.dart';
import '../widgets/platform_modal.dart';
import '../widgets/premium_logo.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'auth_screen.dart';
import 'product_detail_screen.dart';


/// Premium Midnight home dashboard with interactive empty state.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedProductId;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkForConfetti(List<Product> products) {
    if (products.any((p) => p.isPriceBelowTarget)) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final isScrapingNow = ref.watch(isScraping);

    // Trigger confetti if data changes and we have a hit
    productsAsync.whenData(_checkForConfetti);

    return Stack(
      children: [
        PatternBackground(
          child: SafeArea(
            child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          onRefresh: () => ref.read(productsProvider.notifier).loadProducts(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Column(
                    children: [
                      Consumer(
                        builder: (context, ref, _) {
                          final userAsync = ref.watch(authStateProvider);
                          final user = userAsync.value;
                          
                          if (user == null) {
                            return const SizedBox.shrink();
                          }
                          
                          final displayName = user.email?.split('@')[0] ?? 'Warrior';
                          
                          return Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: NinjaColors.glassBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: NinjaColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: NinjaColors.emerald,
                                    shape: BoxShape.circle,
                                  ),
                                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                                const SizedBox(width: 10),
                                Text(
                                  'NINJA: ${displayName.toUpperCase()}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: NinjaColors.textSecondary,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Scrape button
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Center(
                    child: NeonButton(
                      text: 'Scrape All Prices',
                      icon: Icons.rocket_launch_rounded,
                      isLoading: isScrapingNow,
                      onPressed: () => _scrapeAll(ref),
                    ),
                  ),
                ),
              ),

              // Content
              productsAsync.when(
                loading: () => SliverToBoxAdapter(child: _buildShimmer()),
                error: (err, _) =>
                    SliverToBoxAdapter(child: _buildError(err.toString())),
                data: (products) {
                  if (products.isEmpty) {
                    return SliverToBoxAdapter(child: _buildInteractiveEmpty());
                  }

                  final activeProduct = _selectedProductId != null
                      ? products.firstWhere(
                          (p) => p.id == _selectedProductId,
                          orElse: () => products.first)
                      : products.first;

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      _buildFocusHeader(activeProduct),
                      const SizedBox(height: 12),
                      if (products.length > 1) _buildProductPills(products),
                      _buildProductsHeader(products.length),
                      _buildSearchBar(ref),
                      const SizedBox(height: 12),
                      ...products.asMap().entries.map((e) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: ProductCard(
                              product: e.value,
                              index: e.key,
                              onTap: () {
                                setState(() => _selectedProductId = e.value.id);
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, animation, __) =>
                                        ProductDetailScreen(product: e.value),
                                    transitionsBuilder: (_, animation, __, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 300),
                                  ),
                                );
                              },
                              onFavorite: () => ref
                                  .read(productsProvider.notifier)
                                  .toggleFavorite(
                                      e.value.id, !e.value.isFavorite),
                              onDelete: () => _confirmDelete(ref, e.value),
                            ),
                          )),
                      const SizedBox(height: 20),
                      _buildChartSection(activeProduct),
                      const SizedBox(height: 12),
                      _buildPredictionSection(activeProduct),
                      _buildMetrics(activeProduct),
                      const SizedBox(height: 100),
                    ]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
    Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        colors: const [NinjaColors.violet, NinjaColors.blue, NinjaColors.emerald, NinjaColors.amber],
      ),
    ),
  ],
);
  }

  // ─────────── Interactive Empty State ───────────
  Widget _buildInteractiveEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Welcome card
          _WelcomeCard(
            onGetStarted: () => _showPlatformPicker(),
          ),
          const SizedBox(height: 20),

          // Dashboard Header logic
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
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
              const Text('System Status: Ready',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: NinjaColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),

          // Quick action cards
          _QuickActionCard(
            icon: Icons.link_rounded,
            title: 'Paste a URL',
            subtitle: 'Already have a product link? Paste it directly.',
            color: NinjaColors.violet,
            onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
          ),
          const SizedBox(height: 10),
          _QuickActionCard(
            icon: Icons.store_rounded,
            title: 'Browse Platforms',
            subtitle: 'Choose from Amazon, Flipkart, Myntra & more.',
            color: NinjaColors.blue,
            onTap: () => _showPlatformPicker(),
          ),
          const SizedBox(height: 10),
          _QuickActionCard(
            icon: Icons.search_rounded,
            title: 'Search Products',
            subtitle: 'Find products across supported platforms.',
            color: NinjaColors.emerald,
            onTap: () {
              ref.read(bottomNavIndexProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 28),

          // Platform showcase
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: NinjaColors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NinjaColors.blue.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text('Supported Platforms',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: NinjaColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),

          // Platform chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlatformInfo.all
                .where((p) => p.id != 'other')
                .map((p) => _PlatformChip(
                      platform: p,
                      onTap: () {
                        ref.read(bottomNavIndexProvider.notifier).state = 1;
                      },
                    ))
                .toList(),
          ),

          const SizedBox(height: 28),

          // Trending section
          const _TrendingSection(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showPlatformPicker() async {
    final platform = await PlatformSelectionModal.show(context);
    if (platform != null && mounted) {
      ref.read(bottomNavIndexProvider.notifier).state = 1;
    }
  }

  // ─────────── Products Header ───────────
  Widget _buildProductsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: NinjaColors.violet,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NinjaColors.violet.withValues(alpha: 0.5),
                  blurRadius: 6,
                )
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Text('Tracked Products',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: NinjaColors.textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: NinjaColors.violet.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: NinjaColors.violet)),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: NinjaColors.violet, size: 20),
            onPressed: () => ref.read(productsProvider.notifier).loadProducts(),
            tooltip: 'Refresh Now',
          ),
        ],
      ),
    );
  }

  // ─────────── Focus Header (Master Detail) ───────────
  Widget _buildFocusHeader(Product p) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NinjaColors.glassBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NinjaColors.border),
        boxShadow: [
          BoxShadow(
            color: NinjaColors.violet.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Display
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: NinjaColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NinjaColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(Icons.shopping_bag, color: NinjaColors.textMuted),
                      )
                    : const Icon(Icons.shopping_bag, color: NinjaColors.textMuted),
              ).animate().scale(delay: 200.ms),
              const SizedBox(width: 16),
              // Name and Platform
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NinjaColors.violet.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.platform.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: NinjaColors.violet,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: NinjaColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Tactical Pricing Matrix
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceStat('ACTUAL', p.currentPrice, NinjaColors.textPrimary),
              _buildPriceStat('AVERAGE', p.averagePrice, NinjaColors.blue),
              _buildPriceStat('TARGET', p.targetPrice, NinjaColors.emerald),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildPriceStat(String label, double? value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: NinjaColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value != null ? '₹${value.toStringAsFixed(0)}' : '---',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassInput(
        controller: TextEditingController(text: ref.read(searchQueryProvider)),
        onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
        hintText: 'Search products or platforms...',
        prefixIcon: Icons.search_rounded,
        suffix: ref.watch(searchQueryProvider).isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, color: NinjaColors.textMuted, size: 18),
                onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
              )
            : null,
      ),
    );
  }

  // ─────────── Metrics ───────────
  Widget _buildMetrics(Product p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: _cardWidth(context),
            child: MetricCard(
              label: 'Current',
              value: p.currentPrice != null
                  ? '₹${p.currentPrice!.toStringAsFixed(0)}'
                  : 'N/A',
              icon: Icons.payments_outlined,
              colorIndex: 0,
              backContent:
                  'Target: ₹${p.targetPrice.toStringAsFixed(0)}\n${p.isPriceBelowTarget ? '🎯 Below target!' : '⏳ Waiting...'}',
              delayMs: 0,
            ),
          ),
          SizedBox(
            width: _cardWidth(context),
            child: MetricCard(
              label: 'Lowest',
              value: p.lowestPrice != null
                  ? '₹${p.lowestPrice!.toStringAsFixed(0)}'
                  : 'N/A',
              icon: Icons.trending_down_rounded,
              colorIndex: 1,
              backContent: 'All-time lowest',
              delayMs: 100,
            ),
          ),
          SizedBox(
            width: _cardWidth(context),
            child: MetricCard(
              label: 'Highest',
              value: p.highestPrice != null
                  ? '₹${p.highestPrice!.toStringAsFixed(0)}'
                  : 'N/A',
              icon: Icons.trending_up_rounded,
              colorIndex: 2,
              backContent: 'Peak price observed',
              delayMs: 200,
            ),
          ),
          SizedBox(
            width: _cardWidth(context),
            child: MetricCard(
              label: 'Average',
              value: p.averagePrice != null
                  ? '₹${p.averagePrice!.toStringAsFixed(0)}'
                  : 'N/A',
              icon: Icons.analytics_outlined,
              colorIndex: 3,
              backContent: '${p.totalChecks} checks',
              delayMs: 300,
            ),
          ),
        ],
      ),
    );
  }

  double _cardWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 900) return (w - 32 - 24) / 3 - 1;
    return (w - 32 - 12) / 2 - 1;
  }

  Widget _buildProductPills(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (_, i) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final p = products[i];
            final isActive = p.id == (_selectedProductId ?? products.first.id);
            final accent = NinjaColors.accentAt(i);
            return GestureDetector(
              onTap: () => setState(() => _selectedProductId = p.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? accent.withValues(alpha: 0.12)
                      : NinjaColors.glassBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? accent.withValues(alpha: 0.4)
                        : NinjaColors.border,
                  ),
                ),
                child: Text(
                  p.name.length > 20
                      ? '${p.name.substring(0, 20)}...'
                      : p.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? accent : NinjaColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChartSection(Product p) {
    final trendAsync = ref.watch(priceTrendProvider(p.id));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: trendAsync.when(
        loading: () => Container(
          height: 240,
          decoration: BoxDecoration(
            color: NinjaColors.glassBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NinjaColors.border),
          ),
          child: const Center(
            child: CircularProgressIndicator(
                color: NinjaColors.violet, strokeWidth: 2),
          ),
        ),
        error: (_, e) => PriceChart(trendData: const [], productName: p.name),
        data: (trend) => PriceChart(trendData: trend, productName: p.name),
      ),
    );
  }

  Widget _buildPredictionSection(Product p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: PredictionWidget(product: p),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surface,
        highlightColor: Theme.of(context).cardTheme.shadowColor?.withValues(alpha: 0.05) ?? Colors.grey.withValues(alpha: 0.1),
        child: Column(
          children: List.generate(
            4,
            (i) => Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: double.infinity, height: 14, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 14, color: Colors.white),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(width: 60, height: 20, color: Colors.white),
                            Container(width: 40, height: 20, color: Colors.white),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: NinjaColors.glassBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NinjaColors.rose.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 40, color: NinjaColors.rose),
            const SizedBox(height: 16),
            const Text('Connection Error',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: NinjaColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Is the backend running?\n$message',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: NinjaColors.textSecondary)),
            const SizedBox(height: 20),
            NeonButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              colorIndex: 2,
              onPressed: () =>
                  ref.read(productsProvider.notifier).loadProducts(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scrapeAll(WidgetRef ref) async {
    ref.read(isScraping.notifier).state = true;
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.scrapeAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: NinjaColors.surface,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Scraped ${result['products_scraped']} products, ${result['alerts_sent']} alerts sent',
            style: const TextStyle(
                color: NinjaColors.emerald, fontWeight: FontWeight.w500),
          ),
        ));
      }
      ref.read(productsProvider.notifier).loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: NinjaColors.surface,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text('Scrape failed: $e',
              style: const TextStyle(
                  color: NinjaColors.rose, fontWeight: FontWeight.w500)),
        ));
      }
    } finally {
      ref.read(isScraping.notifier).state = false;
    }
  }

  void _confirmDelete(WidgetRef ref, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NinjaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: NinjaColors.border),
        ),
        title: const Text('Delete Product?',
            style: TextStyle(
                color: NinjaColors.textPrimary, fontWeight: FontWeight.w600)),
        content: Text('Remove "${p.name}" from tracking?',
            style: const TextStyle(color: NinjaColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: NinjaColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(productsProvider.notifier).deleteProduct(p.id);
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: NinjaColors.rose, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ────────────── Internal Widgets ──────────────

class _WelcomeCard extends StatefulWidget {
  final VoidCallback onGetStarted;

  const _WelcomeCard({required this.onGetStarted});

  @override
  State<_WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<_WelcomeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glow = 0.1 + _controller.value * 0.15;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                NinjaColors.violet.withValues(alpha: 0.12),
                NinjaColors.blue.withValues(alpha: 0.08),
                NinjaColors.emerald.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: NinjaColors.violet.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: NinjaColors.violet.withValues(alpha: glow),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Animated status icon instead of logo redudancy
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NinjaColors.violet.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: NinjaColors.violet.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.analytics_outlined, size: 36, color: NinjaColors.violet),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Intelligence Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: NinjaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track prices across Amazon, Flipkart, and more.\nGet notified when prices drop below your target.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: NinjaColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              NeonButton(
                text: 'Get Started',
                icon: Icons.arrow_forward_rounded,
                onPressed: widget.onGetStarted,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.08)
                : NinjaColors.glassBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.3)
                  : NinjaColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: NinjaColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: TextStyle(
                            fontSize: 12, color: NinjaColors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: NinjaColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformChip extends StatelessWidget {
  final PlatformInfo platform;
  final VoidCallback onTap;

  const _PlatformChip({required this.platform, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: platform.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: platform.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(platform.icon, size: 16, color: platform.color),
            const SizedBox(width: 8),
            Text(
              platform.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: platform.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingSection extends StatelessWidget {
  // Mock trending data — in production, fetch from backend
  final _trending = const [
    {'name': 'iPhone 15 Pro', 'platform': 'Amazon', 'range': '₹1.1L – ₹1.3L', 'icon': '📱'},
    {'name': 'MacBook Air M3', 'platform': 'Flipkart', 'range': '₹99K – ₹1.1L', 'icon': '💻'},
    {'name': 'Sony WH-1000XM5', 'platform': 'Amazon', 'range': '₹24K – ₹30K', 'icon': '🎧'},
    {'name': 'Samsung S24 Ultra', 'platform': 'Croma', 'range': '₹1.2L – ₹1.4L', 'icon': '📱'},
  ];

  const _TrendingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: NinjaColors.emerald,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NinjaColors.emerald.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text('Trending Products',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: NinjaColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 14),
        ..._trending.asMap().entries.map((e) {
          final t = e.value;
          final accent = NinjaColors.accentAt(e.key);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NinjaColors.glassBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NinjaColors.border),
            ),
            child: Row(
              children: [
                Text(t['icon']!, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['name']!,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: NinjaColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('${t['platform']} • ${t['range']}',
                          style: TextStyle(
                              fontSize: 12, color: NinjaColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('HOT',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
