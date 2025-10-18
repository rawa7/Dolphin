class DeliveryStatus {
  final int customerId;
  final String name;
  final String phone;
  final int deliveryStatus;
  final bool deliveryEnabled;
  final String deliveryText;

  DeliveryStatus({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.deliveryStatus,
    required this.deliveryEnabled,
    required this.deliveryText,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryStatus(
      customerId: json['customer_id'] is int
          ? json['customer_id']
          : int.tryParse(json['customer_id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      deliveryStatus: json['delivery_status'] is int
          ? json['delivery_status']
          : int.tryParse(json['delivery_status'].toString()) ?? 0,
      deliveryEnabled: json['delivery_enabled'] == true || json['delivery_enabled'] == 1,
      deliveryText: json['delivery_text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'name': name,
      'phone': phone,
      'delivery_status': deliveryStatus,
      'delivery_enabled': deliveryEnabled,
      'delivery_text': deliveryText,
    };
  }
}

