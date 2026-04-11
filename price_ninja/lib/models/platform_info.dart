import 'package:flutter/material.dart';
import '../config/color_constants.dart';

/// Supported e-commerce platform definitions.
class PlatformInfo {
  final String id;
  final String name;
  final String domain;
  final String searchUrl;
  final IconData icon; // Fallback
  final String? assetPath;
  final Color color;
  final String hint;

  const PlatformInfo({
    required this.id,
    required this.name,
    required this.domain,
    required this.searchUrl,
    required this.icon,
    this.assetPath,
    required this.color,
    required this.hint,
  });

  static const List<PlatformInfo> all = [
    PlatformInfo(
      id: 'amazon',
      name: 'Amazon India',
      domain: 'amazon.in',
      searchUrl: 'https://www.amazon.in/s?k=',
      icon: Icons.shopping_bag_rounded,
      assetPath: 'assets/logos/amazon.png',
      color: NinjaColors.amber,
      hint: 'https://www.amazon.in/dp/...',
    ),
    PlatformInfo(
      id: 'flipkart',
      name: 'Flipkart',
      domain: 'flipkart.com',
      searchUrl: 'https://www.flipkart.com/search?q=',
      icon: Icons.shopping_cart_rounded,
      assetPath: 'assets/logos/flipkart.png',
      color: NinjaColors.blue,
      hint: 'https://www.flipkart.com/...',
    ),
    PlatformInfo(
      id: 'myntra',
      name: 'Myntra',
      domain: 'myntra.com',
      searchUrl: 'https://www.myntra.com/',
      icon: Icons.checkroom_rounded,
      assetPath: 'assets/logos/myntra.png',
      color: NinjaColors.rose,
      hint: 'https://www.myntra.com/...',
    ),
    PlatformInfo(
      id: 'croma',
      name: 'Croma',
      domain: 'croma.com',
      searchUrl: 'https://www.croma.com/searchB?q=',
      icon: Icons.devices_rounded,
      assetPath: 'assets/logos/croma.png',
      color: NinjaColors.emerald,
      hint: 'https://www.croma.com/...',
    ),
    PlatformInfo(
      id: 'ajio',
      name: 'AJIO',
      domain: 'ajio.com',
      searchUrl: 'https://www.ajio.com/search/?text=',
      icon: Icons.style_rounded,
      assetPath: 'assets/logos/ajio.png',
      color: NinjaColors.violet,
      hint: 'https://www.ajio.com/...',
    ),
    PlatformInfo(
      id: 'ebay',
      name: 'eBay',
      domain: 'ebay.com',
      searchUrl: 'https://www.ebay.com/sch/i.html?_nkw=',
      icon: Icons.shopping_bag_outlined,
      assetPath: null, // fallback to icon
      color: NinjaColors.amber,
      hint: 'https://www.ebay.com/itm/...',
    ),
    PlatformInfo(
      id: 'other',
      name: 'Other',
      domain: '',
      searchUrl: '',
      icon: Icons.language_rounded,
      assetPath: null,
      color: NinjaColors.textMuted,
      hint: 'Paste any product URL',
    ),
  ];

  static PlatformInfo? detect(String url) {
    final lower = url.toLowerCase();
    for (final p in all) {
      if (p.domain.isNotEmpty && lower.contains(p.domain)) return p;
    }
    return null;
  }
}
