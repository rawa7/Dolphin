class ProfileData {
  final Profile profile;
  final ProfileAccountInfo accountInfo;
  final Summary summary;

  ProfileData({
    required this.profile,
    required this.accountInfo,
    required this.summary,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      profile: Profile.fromJson(json['profile']),
      accountInfo: ProfileAccountInfo.fromJson(json['account_info']),
      summary: Summary.fromJson(json['summary']),
    );
  }
}

class Profile {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String email;
  final String usertype;
  final String usertypeName;
  final String isActive;
  final bool hasPassword;

  Profile({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
    required this.usertype,
    required this.usertypeName,
    required this.isActive,
    required this.hasPassword,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      usertype: json['usertype']?.toString() ?? '',
      usertypeName: json['usertype_name']?.toString() ?? '',
      isActive: json['is_active']?.toString() ?? '1',
      hasPassword: json['has_password'] == true,
    );
  }
}

class ProfileAccountInfo {
  final int customerId;
  final String customerName;
  final String customerCode;
  final double currentBalance;
  final String accountType;
  final double debtLimit;
  final double ordersAwaitingPayment;
  final double availableCapacity;

  ProfileAccountInfo({
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.currentBalance,
    required this.accountType,
    required this.debtLimit,
    required this.ordersAwaitingPayment,
    required this.availableCapacity,
  });

  factory ProfileAccountInfo.fromJson(Map<String, dynamic> json) {
    return ProfileAccountInfo(
      customerId: json['customer_id'] is int 
          ? json['customer_id'] 
          : int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
      customerName: json['customer_name']?.toString() ?? '',
      customerCode: json['customer_code']?.toString() ?? '',
      currentBalance: (json['current_balance'] is num)
          ? (json['current_balance'] as num).toDouble()
          : double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      accountType: json['account_type']?.toString() ?? '',
      debtLimit: (json['debt_limit'] is num)
          ? (json['debt_limit'] as num).toDouble()
          : double.tryParse(json['debt_limit']?.toString() ?? '0') ?? 0.0,
      ordersAwaitingPayment: (json['orders_awaiting_payment'] is num)
          ? (json['orders_awaiting_payment'] as num).toDouble()
          : double.tryParse(json['orders_awaiting_payment']?.toString() ?? '0') ?? 0.0,
      availableCapacity: (json['available_capacity'] is num)
          ? (json['available_capacity'] as num).toDouble()
          : double.tryParse(json['available_capacity']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class Summary {
  final int totalItems;
  final int activeItems;
  final int excludedItems;
  final double totalPurchases;
  final double totalPayments;
  final int totalPaidItems;

  Summary({
    required this.totalItems,
    required this.activeItems,
    required this.excludedItems,
    required this.totalPurchases,
    required this.totalPayments,
    required this.totalPaidItems,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalItems: json['total_items'] is int
          ? json['total_items']
          : int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      activeItems: json['active_items'] is int
          ? json['active_items']
          : int.tryParse(json['active_items']?.toString() ?? '0') ?? 0,
      excludedItems: json['excluded_items'] is int
          ? json['excluded_items']
          : int.tryParse(json['excluded_items']?.toString() ?? '0') ?? 0,
      totalPurchases: (json['total_purchases'] is num)
          ? (json['total_purchases'] as num).toDouble()
          : double.tryParse(json['total_purchases']?.toString() ?? '0') ?? 0.0,
      totalPayments: (json['total_payments'] is num)
          ? (json['total_payments'] as num).toDouble()
          : double.tryParse(json['total_payments']?.toString() ?? '0') ?? 0.0,
      totalPaidItems: json['total_paid_items'] is int
          ? json['total_paid_items']
          : int.tryParse(json['total_paid_items']?.toString() ?? '0') ?? 0,
    );
  }
}

