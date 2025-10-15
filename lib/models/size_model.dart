class Size {
  final int id;
  final String name;

  Size({
    required this.id,
    required this.name,
  });

  factory Size.fromJson(Map<String, dynamic> json) {
    return Size(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => name;
}

