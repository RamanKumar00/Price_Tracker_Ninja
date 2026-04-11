/// Data model for a tracked product.
class Product {
  final String id;
  String name;
  final String url;
  String? imageUrl;
  final String platform;
  double? currentPrice;
  double? lowestPrice;
  double? highestPrice;
  double? averagePrice;
  double targetPrice;
  int totalChecks;
  AlertConfig alertConfig;
  bool isFavorite;
  DateTime? lastChecked;
  final DateTime createdAt;
  DateTime updatedAt;
  double? startingPrice;
  DateTime? expiresAt;

  Product({
    required this.id,
    required this.name,
    required this.url,
    this.imageUrl,
    this.platform = 'Unknown',
    this.currentPrice,
    this.lowestPrice,
    this.highestPrice,
    this.averagePrice,
    this.targetPrice = 0,
    this.totalChecks = 0,
    AlertConfig? alertConfig,
    this.isFavorite = false,
    this.lastChecked,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.startingPrice,
    this.expiresAt,
  })  : alertConfig = alertConfig ?? AlertConfig(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      url: json['url'] ?? '',
      imageUrl: json['image_url'],
      platform: json['platform'] ?? 'Unknown',
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      lowestPrice: (json['lowest_price'] as num?)?.toDouble(),
      highestPrice: (json['highest_price'] as num?)?.toDouble(),
      averagePrice: (json['average_price'] as num?)?.toDouble(),
      targetPrice: (json['target_price'] as num?)?.toDouble() ?? 0,
      totalChecks: json['total_checks'] ?? 0,
      alertConfig: json['alert_config'] != null
          ? AlertConfig.fromJson(json['alert_config'])
          : AlertConfig(),
      isFavorite: json['is_favorite'] ?? false,
      lastChecked: json['last_checked'] != null
          ? DateTime.tryParse(json['last_checked'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
      startingPrice: (json['starting_price'] as num?)?.toDouble(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'image_url': imageUrl,
        'platform': platform,
        'current_price': currentPrice,
        'lowest_price': lowestPrice,
        'highest_price': highestPrice,
        'average_price': averagePrice,
        'target_price': targetPrice,
        'total_checks': totalChecks,
        'alert_config': alertConfig.toJson(),
        'is_favorite': isFavorite,
        'last_checked': lastChecked?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'starting_price': startingPrice,
        'expires_at': expiresAt?.toIso8601String(),
      };

  double? get changePercent {
    if (currentPrice == null || lowestPrice == null || lowestPrice == 0) {
      return null;
    }
    return ((currentPrice! - lowestPrice!) / lowestPrice!) * 100;
  }

  bool get isPriceBelowTarget =>
      currentPrice != null && targetPrice > 0 && currentPrice! <= targetPrice;
}

class AlertConfig {
  bool emailEnabled;
  bool whatsappEnabled;
  bool browserEnabled;
  String emailAddress;
  String whatsappNumber;

  AlertConfig({
    this.emailEnabled = true,
    this.whatsappEnabled = false,
    this.browserEnabled = true,
    this.emailAddress = '',
    this.whatsappNumber = '',
  });

  factory AlertConfig.fromJson(Map<String, dynamic> json) {
    return AlertConfig(
      emailEnabled: json['email_enabled'] ?? true,
      whatsappEnabled: json['whatsapp_enabled'] ?? false,
      browserEnabled: json['browser_enabled'] ?? true,
      emailAddress: json['email_address'] ?? '',
      whatsappNumber: json['whatsapp_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'email_enabled': emailEnabled,
        'whatsapp_enabled': whatsappEnabled,
        'browser_enabled': browserEnabled,
        'email_address': emailAddress,
        'whatsapp_number': whatsappNumber,
      };
}

class PriceEntry {
  final String id;
  final String productId;
  final double price;
  final String currency;
  final DateTime timestamp;
  final double? changePercent;
  final String status;

  PriceEntry({
    required this.id,
    required this.productId,
    required this.price,
    this.currency = '₹',
    DateTime? timestamp,
    this.changePercent,
    this.status = 'ok',
  }) : timestamp = timestamp ?? DateTime.now();

  factory PriceEntry.fromJson(Map<String, dynamic> json) {
    return PriceEntry(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? '₹',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      changePercent: (json['change_percent'] as num?)?.toDouble(),
      status: json['status'] ?? 'ok',
    );
  }
}

class AlertRecord {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final double targetPrice;
  final String alertType;
  final DateTime sentAt;
  final bool success;
  final String? errorMessage;

  AlertRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.targetPrice,
    required this.alertType,
    DateTime? sentAt,
    this.success = true,
    this.errorMessage,
  }) : sentAt = sentAt ?? DateTime.now();

  factory AlertRecord.fromJson(Map<String, dynamic> json) {
    return AlertRecord(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      targetPrice: (json['target_price'] as num?)?.toDouble() ?? 0,
      alertType: json['alert_type'] ?? '',
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      success: json['success'] ?? true,
      errorMessage: json['error_message'],
    );
  }
}
