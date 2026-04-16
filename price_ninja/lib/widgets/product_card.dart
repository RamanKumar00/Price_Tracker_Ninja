import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/color_constants.dart';
import '../models/product.dart';
import 'trend_indicator.dart';

/// Premium product card — frosted glass, accent border highlight, clean layout.
class ProductCard extends StatefulWidget {
  final Product product;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;

  const ProductCard({
    super.key,
    required this.product,
    this.index = 0,
    this.onTap,
    this.onDelete,
    this.onFavorite,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final accent = NinjaColors.accentAt(widget.index);
    final priceStr = p.currentPrice != null
        ? '₹${p.currentPrice!.toStringAsFixed(0)}'
        : 'N/A';

    return Dismissible(
      key: Key('product_${p.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
      },
      confirmDismiss: (direction) async {
        // Just trigger delete callback, the home screen handle the confirm dialog already
        // Wait, the home_screen does showDialog and calls deleteProduct inside it.
        // If we swipe, we should probably return false but trigger the dialog.
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
        return false; // Prevent automatic dismissal so the dialog can handle it
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: NinjaColors.rose.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NinjaColors.rose.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: NinjaColors.rose, size: 28),
      ),
      child: FadeTransition(
        opacity: _entryController,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _entryController,
            curve: Curves.easeOutCubic,
          )),
          child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isHovered
                    ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? accent.withValues(alpha: 0.4)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  // Image
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.2)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: p.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, url) => _buildShimmerIcon(accent),
                            errorWidget: (_, url, err) => _buildShimmerIcon(accent),
                          )
                        : _buildShimmerIcon(accent),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _platformBadge(p.platform, accent),
                            const Spacer(),
                            if (p.isPriceBelowTarget)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: NinjaColors.emerald
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '🎯 Target Hit',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: NinjaColors.emerald,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              priceStr,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (p.changePercent != null) TrendIndicator(changePercent: p.changePercent!),
                            const Spacer(),
                            GestureDetector(
                              onTap: widget.onFavorite,
                              child: Icon(
                                p.isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: p.isFavorite
                                    ? NinjaColors.amber
                                    : Theme.of(context).hintColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTap: widget.onDelete,
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: NinjaColors.rose.withValues(alpha: 0.7),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _platformBadge(String platform, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        platform.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: accent,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildShimmerIcon(Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: 0.2),
            Colors.transparent,
          ],
          radius: 0.8,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.shopping_bag_rounded,
          size: 24,
          color: accent.withValues(alpha: 0.4),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.5.seconds),
      ),
    );
  }



  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }
}
