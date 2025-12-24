class ShopBanner {
  final int bannerId;
  final String title;
  final String description;
  final int productId;
  final String productName;
  final double productPrice;
  final String brandName;
  final String bannerImage;
  final String productImage;

  ShopBanner({
    required this.bannerId,
    required this.title,
    required this.description,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.brandName,
    required this.bannerImage,
    required this.productImage,
  });

  factory ShopBanner.fromJson(Map<String, dynamic> json) {
    return ShopBanner(
      bannerId: int.tryParse(json['banner_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? '',
      productPrice: (json['product_price'] is num)
          ? (json['product_price'] as num).toDouble()
          : double.tryParse(json['product_price']?.toString() ?? '0') ?? 0.0,
      brandName: json['brand_name']?.toString() ?? '',
      bannerImage: json['banner_image']?.toString() ?? '',
      productImage: json['product_image']?.toString() ?? '',
    );
  }
}

