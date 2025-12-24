class ShopItem {
  final String itemId;
  final String itemName;
  final String itemNameKurdish;
  final String itemNameArabic;
  final String brandId;
  final String brandName;
  final String brandImageId;
  final String brandImageUrl;
  final String itemCategory;
  final String itemCategoryKurdish;
  final String itemCategoryArabic;
  final double price;
  final String imageid;
  final String? imageid2;
  final String? imageid3;
  final String? imageid4;
  final String imagePath;
  final String filename;
  final String itemDescription;
  final String itemDescriptionKurdish;
  final String itemDescriptionArabic;

  ShopItem({
    required this.itemId,
    required this.itemName,
    required this.itemNameKurdish,
    required this.itemNameArabic,
    required this.brandId,
    required this.brandName,
    required this.brandImageId,
    required this.brandImageUrl,
    required this.itemCategory,
    required this.itemCategoryKurdish,
    required this.itemCategoryArabic,
    required this.price,
    required this.imageid,
    this.imageid2,
    this.imageid3,
    this.imageid4,
    required this.imagePath,
    required this.filename,
    required this.itemDescription,
    required this.itemDescriptionKurdish,
    required this.itemDescriptionArabic,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      itemId: json['item_id']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      itemNameKurdish: json['item_name_kurdish']?.toString() ?? '',
      itemNameArabic: json['item_name_arabic']?.toString() ?? '',
      brandId: json['brand_id']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? '',
      brandImageId: json['brand_image_id']?.toString() ?? '',
      brandImageUrl: json['brand_image_url']?.toString() ?? '',
      itemCategory: json['item_category']?.toString() ?? '',
      itemCategoryKurdish: json['item_category_kurdish']?.toString() ?? '',
      itemCategoryArabic: json['item_category_arabic']?.toString() ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageid: json['imageid']?.toString() ?? '',
      imageid2: json['imageid2']?.toString(),
      imageid3: json['imageid3']?.toString(),
      imageid4: json['imageid4']?.toString(),
      imagePath: json['image_path']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      itemDescription: json['item_description']?.toString() ?? '',
      itemDescriptionKurdish: json['item_description_kurdish']?.toString() ?? '',
      itemDescriptionArabic: json['item_description_arabic']?.toString() ?? '',
    );
  }

  List<String> get allImages {
    final images = <String>[imagePath];
    if (imageid2 != null && imageid2!.isNotEmpty) {
      images.add('https://dolphinshippingiq.com/images/$imageid2.png');
    }
    if (imageid3 != null && imageid3!.isNotEmpty) {
      images.add('https://dolphinshippingiq.com/images/$imageid3.png');
    }
    if (imageid4 != null && imageid4!.isNotEmpty) {
      images.add('https://dolphinshippingiq.com/images/$imageid4.png');
    }
    return images;
  }
}

class Brand {
  final String brandId;
  final String brandName;
  final String brandImageUrl;

  Brand({
    required this.brandId,
    required this.brandName,
    required this.brandImageUrl,
  });
}

