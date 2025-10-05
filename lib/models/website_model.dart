class Website {
  final int id;
  final String name;
  final String link;
  final int orderId;
  final String country;
  final String? imageId;
  final String? webPath;
  final String? filename;
  final String? imageUrl;

  Website({
    required this.id,
    required this.name,
    required this.link,
    required this.orderId,
    required this.country,
    this.imageId,
    this.webPath,
    this.filename,
    this.imageUrl,
  });

  factory Website.fromJson(Map<String, dynamic> json) {
    return Website(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      link: json['link'] ?? '',
      orderId: int.parse(json['order_id']?.toString() ?? '0'),
      country: json['country'] ?? '',
      imageId: json['image_id']?.toString(),
      webPath: json['web_path'],
      filename: json['filename'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'link': link,
      'order_id': orderId,
      'country': country,
      'image_id': imageId,
      'web_path': webPath,
      'filename': filename,
      'image_url': imageUrl,
    };
  }

  // Check if website is valid (has country and order_id set)
  bool get isValid => country != '0' && country.isNotEmpty && orderId > 0;
}

