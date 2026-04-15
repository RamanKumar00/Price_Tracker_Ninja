/// Riverpod providers for state management.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// ─────────── API Service Provider ───────────
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// ─────────── Products State ───────────
final productsProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ProductsNotifier(api);
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ApiService _api;

  ProductsNotifier(this._api) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await _api.getProducts();
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Product> addProduct({
    required String url,
    String? name,
    double targetPrice = 0,
    bool emailEnabled = true,
    bool whatsappEnabled = false,
    String emailAddress = '',
    String whatsappNumber = '',
    DateTime? expiresAt,
  }) async {
    final product = await _api.addProduct(
      url: url,
      name: name,
      targetPrice: targetPrice,
      emailEnabled: emailEnabled,
      whatsappEnabled: whatsappEnabled,
      emailAddress: emailAddress,
      whatsappNumber: whatsappNumber,
      expiresAt: expiresAt,
    );
    await loadProducts();
    return product;
  }

  Future<void> deleteProduct(String id) async {
    await _api.deleteProduct(id);
    await loadProducts();
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _api.updateProduct(id, {'is_favorite': isFavorite});
    await loadProducts();
  }

  Future<void> updateTargetPrice(String id, double price) async {
    await _api.updateProduct(id, {'target_price': price});
    await loadProducts();
  }
}

// ─────────── Selected Product ───────────
final selectedProductIdProvider = StateProvider<String?>((ref) => null);

final selectedProductProvider = Provider<Product?>((ref) {
  final id = ref.watch(selectedProductIdProvider);
  final productsAsync = ref.watch(productsProvider);
  if (id == null) return null;
  return productsAsync.whenData((products) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }).value;
});

// ─────────── Price History ───────────
final priceHistoryProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, productId) async {
  final api = ref.read(apiServiceProvider);
  return api.getPriceHistory(productId);
});

final priceTrendProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, productId) async {
  final api = ref.read(apiServiceProvider);
  return api.getPriceTrend(productId);
});

// ─────────── Scrape Status ───────────
final isScraping = StateProvider<bool>((ref) => false);

// ─────────── Alert History ───────────
final alertHistoryProvider =
    FutureProvider<List<AlertRecord>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getAlertHistory();
});

// ─────────── Bottom Nav Index ───────────
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
