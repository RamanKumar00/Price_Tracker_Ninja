import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'providers.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  return productsAsync.whenData((products) {
    if (searchQuery.isEmpty) return products;
    
    return products.where((product) {
      final matchesName = product.name.toLowerCase().contains(searchQuery);
      final matchesPlatform = product.platform.toLowerCase().contains(searchQuery);
      return matchesName || matchesPlatform;
    }).toList();
  });
});
