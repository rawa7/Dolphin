class BannerItem {
  final String id;
  final String image;
  final String link;
  final String position;

  BannerItem({
    required this.id,
    required this.image,
    required this.link,
    required this.position,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      position: json['position']?.toString() ?? '0',
    );
  }
}

