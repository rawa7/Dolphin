class BannerItem {
  final String id;
  final String image;
  final String link;
  final String position;
  final bool isLocalAsset;

  BannerItem({
    required this.id,
    required this.image,
    this.link = '',
    this.position = '0',
    this.isLocalAsset = false,
  });

  // Named constructor for imageUrl (backwards compatibility)
  BannerItem.fromImageUrl({
    required String id,
    required String imageUrl,
    bool isLocalAsset = false,
  }) : this(
          id: id,
          image: imageUrl,
          link: '',
          position: '0',
          isLocalAsset: isLocalAsset,
        );

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      position: json['position']?.toString() ?? '0',
      isLocalAsset: false,
    );
  }
}

