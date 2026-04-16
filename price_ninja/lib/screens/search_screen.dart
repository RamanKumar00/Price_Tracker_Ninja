import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/color_constants.dart';
import '../models/platform_info.dart';
import '../providers/providers.dart';
import '../services/search_history_service.dart';
import '../widgets/glass_input.dart';
import '../widgets/neon_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';


/// Enhanced Add Product screen — dual mode (URL paste / platform browse),
/// search history, platform context.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _targetPriceController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isValidUrl = false;
  bool _emailEnabled = true;
  bool _whatsappEnabled = false;
  int _selectedTimelineDays = 30; // 30, 90, 180
  String? _errorMsg;
  String? _successMsg;
  PlatformInfo? _selectedPlatform;
  late TabController _tabController;
  List<String> _recentSearches = [];
  
  // Expiry states
  int _expiryIndex = 3; // Default: No Limit
  final List<Map<String, dynamic>> _expiryOptions = [
    {'label': '7 Days', 'days': 7},
    {'label': '1 Month', 'days': 30},
    {'label': '3 Months', 'days': 90},
    {'label': 'No Limit', 'days': null},
  ];

  // Timeline options
  final List<Map<String, dynamic>> _timelineOptions = [
    {'label': '1 Month', 'days': 30},
    {'label': '3 Months', 'days': 90},
    {'label': '6 Months', 'days': 180},
    {'label': 'Forever', 'days': 0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final searches = await SearchHistoryService.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = searches;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(productsProvider);
    final trackedProducts = asyncProducts.valueOrNull?.reversed.take(5).toList() ?? [];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                      const Text('Add Product',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: NinjaColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Track prices by pasting a URL or browsing platforms',
                          style: TextStyle(fontSize: 13, color: NinjaColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tabs — Paste URL / Browse
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: NinjaColors.glassBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NinjaColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {}),
                indicator: BoxDecoration(
                  color: NinjaColors.violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: NinjaColors.violet.withValues(alpha: 0.3)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                labelColor: NinjaColors.violet,
                unselectedLabelColor: NinjaColors.textMuted,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Paste URL'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.store_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Browse'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab content
            IndexedStack(
              index: _tabController.index,
              children: [
                _buildPasteUrlTab(),
                _buildBrowseTab(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── Tab 1: Paste URL ───────────
  Widget _buildPasteUrlTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Platform indicator
        if (_selectedPlatform != null) _platformBanner(_selectedPlatform!),

        GlassInput(
          controller: _urlController,
          hintText: _selectedPlatform?.hint ?? 'https://amazon.in/dp/...',
          labelText: 'Product URL',
          prefixIcon: Icons.link_rounded,
          colorIndex: 0,
          suffix: _isValidUrl
              ? const Icon(Icons.check_circle,
                  color: NinjaColors.emerald, size: 20)
              : null,
          onChanged: (val) {
            final detected = PlatformInfo.detect(val);
            setState(() {
              _isValidUrl = detected != null ||
                  val.startsWith('http://') ||
                  val.startsWith('https://') ||
                  val.contains('.');
              _selectedPlatform = detected;
              _errorMsg = null;
              _successMsg = null;
            });
          },
        ),
        const SizedBox(height: 14),
        GlassInput(
          controller: _nameController,
          hintText: 'Auto-detected if empty',
          labelText: 'Product Name',
          prefixIcon: Icons.label_outline_rounded,
          colorIndex: 1,
        ),
        const SizedBox(height: 14),
        GlassInput(
          controller: _targetPriceController,
          hintText: 'e.g., 9999',
          labelText: 'Target Price (₹)',
          prefixIcon: Icons.flag_outlined,
          keyboardType: TextInputType.number,
          colorIndex: 2,
        ),
        
        const SizedBox(height: 24),
        _sectionHeader('Tracking Duration', NinjaColors.blue),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _timelineOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final opt = _timelineOptions[idx];
              final isSelected = _selectedTimelineDays == opt['days'];
              return GestureDetector(
                onTap: () => setState(() => _selectedTimelineDays = opt['days']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? NinjaColors.blue.withValues(alpha: 0.1) : NinjaColors.glassBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? NinjaColors.blue.withValues(alpha: 0.3) : NinjaColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    opt['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? NinjaColors.blue : NinjaColors.textMuted,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
          const SizedBox(height: 14),
        _sectionHeader('Tracking Expiry', NinjaColors.violet),
        const SizedBox(height: 12),
        _expirySelection(),

        const SizedBox(height: 24),
        _sectionHeader('Alert Channels', NinjaColors.emerald),
        const SizedBox(height: 14),

        // Alert Config Row
        Row(
          children: [
            Expanded(
              child: _alertToggle(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                isActive: _emailEnabled,
                onChanged: (v) => setState(() => _emailEnabled = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _alertToggle(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'WhatsApp',
                isActive: _whatsappEnabled,
                onChanged: (v) => setState(() => _whatsappEnabled = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_emailEnabled)
          GlassInput(
            controller: _emailController,
            hintText: 'your@email.com',
            labelText: 'Alert Email',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            colorIndex: 3,
          ).animate().fadeIn().slideY(begin: 0.1),
        
        if (_whatsappEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: GlassInput(
              controller: _whatsappController,
              hintText: '+91 99999 99999',
              labelText: 'WhatsApp Number',
              prefixIcon: Icons.chat_bubble_outline_rounded,
              keyboardType: TextInputType.phone,
              colorIndex: 0,
            ).animate().fadeIn().slideY(begin: 0.1),
          ),

        const SizedBox(height: 28),

        if (_errorMsg != null) _msgBox(_errorMsg!, NinjaColors.rose),
        if (_successMsg != null) _msgBox(_successMsg!, NinjaColors.emerald),

        Center(
          child: NeonButton(
            text: 'Add to Tracking',
            icon: Icons.rocket_launch_rounded,
            isLoading: _isLoading,
            onPressed: (_isValidUrl && !_isLoading) ? _addProduct : null,
          ),
        ),

        // Recent products
        if (trackedProducts.isNotEmpty) ...[
          const SizedBox(height: 28),
          _sectionHeader('Recent Products', NinjaColors.violet),
          const SizedBox(height: 12),
          ...trackedProducts.map((p) => _recentProductTile(p)),
        ],

        const SizedBox(height: 28),
        _buildTipsCard(),
      ],
    );
  }

  // ─────────── Tab 2: Browse Platforms ───────────
  Widget _buildBrowseTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // In-app search
        GlassInput(
          controller: _searchController,
          hintText: 'Search products...',
          labelText: 'Product Search',
          prefixIcon: Icons.search_rounded,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),

        // Search button
        if (_searchController.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: PlatformInfo.all
                  .where((p) => p.searchUrl.isNotEmpty)
                  .take(3)
                  .map((p) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => _searchOnPlatform(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: p.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: p.color.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                children: [
                                  p.assetPath != null
                                      ? Image.asset(p.assetPath!, width: 20, height: 20, fit: BoxFit.contain)
                                      : Icon(p.icon, color: p.color, size: 18),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Search ${p.name.split(' ').first}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: p.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

        const SizedBox(height: 8),
        _sectionHeader('All Platforms', NinjaColors.blue),
        const SizedBox(height: 12),

        // Platform grid
        ...PlatformInfo.all.map((p) => _platformTile(p)),

        // Recent searches
        if (_recentSearches.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              ..._sectionHeaderWidgets('Search History', NinjaColors.amber),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await SearchHistoryService.clearSearches();
                  _loadHistory();
                },
                child: Text('Clear',
                    style: TextStyle(
                        fontSize: 12,
                        color: NinjaColors.textMuted,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((s) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = s;
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: NinjaColors.glassBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NinjaColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 14, color: NinjaColors.textMuted),
                      const SizedBox(width: 6),
                      Text(s,
                          style: TextStyle(
                              fontSize: 12,
                              color: NinjaColors.textSecondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  // ─────────── Helpers ───────────

  Widget _platformBanner(PlatformInfo p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          p.assetPath != null
              ? Image.asset(p.assetPath!, width: 22, height: 22, fit: BoxFit.contain)
              : Icon(p.icon, color: p.color, size: 20),
          const SizedBox(width: 10),
          Text(
            'Detected: ${p.name}',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: p.color),
          ),
          const Spacer(),
          Icon(Icons.check_circle_rounded,
              size: 18, color: NinjaColors.emerald),
        ],
      ),
    );
  }

  Widget _platformTile(PlatformInfo p) {
    return GestureDetector(
      onTap: () {
        if (p.searchUrl.isNotEmpty) {
          _openPlatformUrl(p);
        }
        setState(() {
          _selectedPlatform = p;
          _tabController.animateTo(0);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NinjaColors.glassBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NinjaColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: p.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: p.assetPath != null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(p.assetPath!, fit: BoxFit.contain),
                    )
                  : Icon(p.icon, color: p.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: NinjaColors.textPrimary)),
                  Text(p.domain.isNotEmpty ? p.domain : 'Any website',
                      style: TextStyle(
                          fontSize: 12, color: NinjaColors.textMuted)),
                ],
              ),
            ),
            if (p.searchUrl.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: p.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new_rounded,
                        size: 12, color: p.color),
                    const SizedBox(width: 4),
                    Text('Browse',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.color)),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: NinjaColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _recentProductTile(Product p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: p),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NinjaColors.glassBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NinjaColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: NinjaColors.violet.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: p.imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2, color: NinjaColors.violet),
                            ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.history_rounded, size: 20, color: NinjaColors.textMuted),
                      ),
                    )
                  : const Icon(Icons.history_rounded, size: 20, color: NinjaColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: NinjaColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(p.platform,
                      style: TextStyle(
                          fontSize: 11, color: NinjaColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 18, color: NinjaColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text, Color color) {
    return Row(children: _sectionHeaderWidgets(text, color));
  }

  List<Widget> _sectionHeaderWidgets(String text, Color color) {
    return [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.5), blurRadius: 6),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: NinjaColors.textPrimary)),
    ];
  }

  Widget _msgBox(String msg, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(msg,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w500, fontSize: 13)),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NinjaColors.glassBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NinjaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tips',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: NinjaColors.textPrimary)),
          const SizedBox(height: 12),
          ...[
            'Copy product URL from any supported platform',
            'Set target price to get email drop alerts',
            'Product name is auto-fetched if left blank',
            'Browse platforms to discover products',
          ].map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('→ ',
                        style: TextStyle(
                            color: NinjaColors.violet,
                            fontWeight: FontWeight.w600)),
                    Expanded(
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 13,
                                color: NinjaColors.textSecondary,
                                height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _expirySelection() {
    return Row(
      children: List.generate(_expiryOptions.length, (index) {
        final opt = _expiryOptions[index];
        final isSelected = _expiryIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _expiryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? NinjaColors.violet.withValues(alpha: 0.15) : NinjaColors.glassBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? NinjaColors.violet.withValues(alpha: 0.4) : NinjaColors.border),
              ),
              child: Text(
                opt['label'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? NinjaColors.violet : NinjaColors.textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _alertToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!isActive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? NinjaColors.emerald.withValues(alpha: 0.1) : NinjaColors.glassBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? NinjaColors.emerald.withValues(alpha: 0.3) : NinjaColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? NinjaColors.emerald : NinjaColors.textMuted, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? NinjaColors.emerald : NinjaColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchOnPlatform(PlatformInfo p) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    await SearchHistoryService.addSearch(query);
    _loadHistory();
    final url = Uri.parse('${p.searchUrl}${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(url)) {
      launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openPlatformUrl(PlatformInfo p) async {
    final uri = Uri.parse('https://www.${p.domain}');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _addProduct() async {
    String url = _urlController.text.trim();
    if (url.isEmpty) return;
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _successMsg = null;
    });
    try {
      final name = _nameController.text.trim();
      final target =
          double.tryParse(_targetPriceController.text.trim()) ?? 0;
      final email = _emailController.text.trim();
      final whatsapp = _whatsappController.text.trim();

      DateTime? expiresAt;
      final days = _expiryOptions[_expiryIndex]['days'];
      if (days != null) {
        expiresAt = DateTime.now().add(Duration(days: days));
      }

      final product = await ref.read(productsProvider.notifier).addProduct(
            url: url,
            name: name.isNotEmpty ? name : null,
            targetPrice: target,
            emailEnabled: _emailEnabled,
            whatsappEnabled: _whatsappEnabled,
            emailAddress: email,
            whatsappNumber: whatsapp,
            expiresAt: expiresAt,
          );

      await SearchHistoryService.addRecentProduct(
        name: product.name,
        url: product.url,
        platform: product.platform,
      );

      if (mounted) {
        _showSuccessDialog(product.name);
      }

      setState(() {
        _urlController.clear();
        _nameController.clear();
        _targetPriceController.clear();
        _whatsappController.clear();
        _isValidUrl = false;
        _selectedPlatform = null;
      });
      _loadHistory();

      // Auto-refresh dashboard after 5s so background-scraped price appears
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          ref.read(productsProvider.notifier).loadProducts();
        }
      });
      // Second refresh at 12s as fallback (slow networks)
      Future.delayed(const Duration(seconds: 12), () {
        if (mounted) {
          ref.read(productsProvider.notifier).loadProducts();
        }
      });

    } catch (e) {
      setState(() => _errorMsg = 'Failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String productName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: NinjaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: NinjaColors.emerald.withValues(alpha: 0.3)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NinjaColors.emerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: NinjaColors.emerald, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tracker Active!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: NinjaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Price Ninja is tracking "$productName".\n\nPrice is being fetched in the background — it will appear on the dashboard in a few seconds! 🎯',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: NinjaColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: NeonButton(
                text: 'Go to Dashboard',
                icon: Icons.dashboard_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(bottomNavIndexProvider.notifier).state = 0;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _targetPriceController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
