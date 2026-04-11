import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks recent searches and recently viewed products locally.
class SearchHistoryService {
  static const _recentSearchesKey = 'recent_searches';
  static const _recentProductsKey = 'recent_products';
  static const int maxItems = 10;

  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  static Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > maxItems) searches.removeLast();
    await prefs.setStringList(_recentSearchesKey, searches);
  }

  static Future<void> clearSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }

  static Future<List<Map<String, String>>> getRecentProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recentProductsKey) ?? [];
    return raw.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
  }

  static Future<void> addRecentProduct({
    required String name,
    required String url,
    required String platform,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recentProductsKey) ?? [];
    final entry = jsonEncode({'name': name, 'url': url, 'platform': platform});
    raw.remove(entry);
    raw.insert(0, entry);
    if (raw.length > maxItems) raw.removeLast();
    await prefs.setStringList(_recentProductsKey, raw);
  }
}
