class Order {
  final String id;
  final String serial;
  final String customerId;
  final String websiteId;
  final String country;
  final String link;
  final String size;
  final String qty;
  final String itemPrice;
  final String cargo;
  final String shippingPrice;
  final String tax;
  final String commission;
  final String totalPrice;
  final String convertToDinar;
  final String status;
  final String? boxId;
  final String image;
  final String adminId;
  final String createdAt;
  final String date;
  final String currencyId;
  final String paymentStatus;
  final String color;
  final String note;
  final String? brandId;
  final String? pCountry;
  final String statusName;
  final String? websiteName;
  final String imagePath;
  final String? currencySymbol;
  final String? currencyName;
  final String imageUrl;

  Order({
    required this.id,
    required this.serial,
    required this.customerId,
    required this.websiteId,
    required this.country,
    required this.link,
    required this.size,
    required this.qty,
    required this.itemPrice,
    required this.cargo,
    required this.shippingPrice,
    required this.tax,
    required this.commission,
    required this.totalPrice,
    required this.convertToDinar,
    required this.status,
    this.boxId,
    required this.image,
    required this.adminId,
    required this.createdAt,
    required this.date,
    required this.currencyId,
    required this.paymentStatus,
    required this.color,
    required this.note,
    this.brandId,
    this.pCountry,
    required this.statusName,
    this.websiteName,
    required this.imagePath,
    this.currencySymbol,
    this.currencyName,
    required this.imageUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      serial: json['serial']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      websiteId: json['websiteid']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      qty: json['qty']?.toString() ?? '',
      itemPrice: json['itemprice']?.toString() ?? '0',
      cargo: json['cargo']?.toString() ?? '0',
      shippingPrice: json['shippingprice']?.toString() ?? '0',
      tax: json['tax']?.toString() ?? '0',
      commission: json['commission']?.toString() ?? '0',
      totalPrice: json['totalprice']?.toString() ?? '0',
      convertToDinar: json['converttodinar']?.toString() ?? '0',
      status: json['status']?.toString() ?? '',
      boxId: json['box_id']?.toString(),
      image: json['image']?.toString() ?? '',
      adminId: json['adminid']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      currencyId: json['currency_id']?.toString() ?? '',
      paymentStatus: json['paymentstatus']?.toString() ?? '0',
      color: json['color']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      brandId: json['brand_id']?.toString(),
      pCountry: json['pcountry']?.toString(),
      statusName: json['status_name']?.toString() ?? '',
      websiteName: json['website_name']?.toString(),
      imagePath: json['image_path']?.toString() ?? '',
      currencySymbol: json['currency_symbol']?.toString(),
      currencyName: json['currency_name']?.toString(),
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}

class OrderStatus {
  final String id;
  final String name;
  final int count;
  final double total;

  OrderStatus({
    required this.id,
    required this.name,
    required this.count,
    required this.total,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class AccountInfo {
  final int customerId;
  final double currentBalance;
  final String accountType;
  final double debtLimit;
  final int ordersAwaitingPayment;
  final double availableCapacity;

  AccountInfo({
    required this.customerId,
    required this.currentBalance,
    required this.accountType,
    required this.debtLimit,
    required this.ordersAwaitingPayment,
    required this.availableCapacity,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      customerId: int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      accountType: json['account_type']?.toString() ?? '',
      debtLimit: double.tryParse(json['debt_limit']?.toString() ?? '0') ?? 0.0,
      ordersAwaitingPayment: int.tryParse(json['orders_awaiting_payment']?.toString() ?? '0') ?? 0,
      availableCapacity: double.tryParse(json['available_capacity']?.toString() ?? '0') ?? 0.0,
    );
  }
}
