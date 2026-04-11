import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/color_constants.dart';
import '../models/platform_info.dart';

/// Bottom sheet modal for selecting an e-commerce platform.
class PlatformSelectionModal extends StatelessWidget {
  final void Function(PlatformInfo platform) onSelect;
  final void Function(PlatformInfo platform)? onBrowse;

  const PlatformSelectionModal({
    super.key,
    required this.onSelect,
    this.onBrowse,
  });

  static Future<PlatformInfo?> show(
    BuildContext context, {
    void Function(PlatformInfo)? onBrowse,
  }) {
    return showModalBottomSheet<PlatformInfo>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => PlatformSelectionModal(
        onSelect: (p) => Navigator.pop(ctx, p),
        onBrowse: onBrowse,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: NinjaColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: NinjaColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: NinjaColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.store_rounded, color: NinjaColors.violet, size: 22),
                SizedBox(width: 10),
                Text(
                  'Choose a Platform',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: NinjaColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select a platform to paste a URL or browse products',
              style: TextStyle(fontSize: 13, color: NinjaColors.textMuted),
            ),
          ),
          const SizedBox(height: 20),

          // Platform grid
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: PlatformInfo.all
                    .map((p) => _PlatformTile(
                          platform: p,
                          onSelect: () => onSelect(p),
                          onBrowse: p.searchUrl.isNotEmpty
                              ? () => _openBrowser(p)
                              : null,
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openBrowser(PlatformInfo p) async {
    final uri = Uri.parse('https://www.${p.domain}');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    onBrowse?.call(p);
  }
}

class _PlatformTile extends StatefulWidget {
  final PlatformInfo platform;
  final VoidCallback onSelect;
  final VoidCallback? onBrowse;

  const _PlatformTile({
    required this.platform,
    required this.onSelect,
    this.onBrowse,
  });

  @override
  State<_PlatformTile> createState() => _PlatformTileState();
}

class _PlatformTileState extends State<_PlatformTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.platform;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered
                ? p.color.withValues(alpha: 0.08)
                : NinjaColors.glassBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? p.color.withValues(alpha: 0.3)
                  : NinjaColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: p.assetPath != null
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(p.assetPath!, fit: BoxFit.contain),
                      )
                    : Icon(p.icon, color: p.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: NinjaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.domain.isNotEmpty ? p.domain : 'Any website',
                      style: TextStyle(
                        fontSize: 12,
                        color: NinjaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onBrowse != null)
                GestureDetector(
                  onTap: widget.onBrowse,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new_rounded,
                            size: 14, color: p.color),
                        const SizedBox(width: 4),
                        Text(
                          'Browse',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: NinjaColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
