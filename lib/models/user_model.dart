class User {
  final int id;
  final String? name;
  final String phone;
  final String? email;
  final String? address;
  final int isActive;
  final String? createdAt;

  User({
    required this.id,
    this.name,
    required this.phone,
    this.email,
    this.address,
    required this.isActive,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      isActive: int.parse(json['is_active'].toString()),
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}

