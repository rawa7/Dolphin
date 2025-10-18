class CustomerStatementCustomer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String usertype;
  final double debtLimit;

  CustomerStatementCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.usertype,
    required this.debtLimit,
  });

  factory CustomerStatementCustomer.fromJson(Map<String, dynamic> json) {
    return CustomerStatementCustomer(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      usertype: json['usertype']?.toString() ?? '',
      debtLimit: json['debt_limit'] is double
          ? json['debt_limit']
          : double.tryParse(json['debt_limit'].toString()) ?? 0.0,
    );
  }
}

class FinancialSummary {
  final double completedPurchasesValue;
  final double totalPayments;
  final double currentBalance;
  final String balanceStatus;
  final double pendingItemsValue;
  final double refundedItemsValue;
  final double ordersAwaitingPayment;
  final double availableCapacity;

  FinancialSummary({
    required this.completedPurchasesValue,
    required this.totalPayments,
    required this.currentBalance,
    required this.balanceStatus,
    required this.pendingItemsValue,
    required this.refundedItemsValue,
    required this.ordersAwaitingPayment,
    required this.availableCapacity,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      completedPurchasesValue: json['completed_purchases_value'] is double
          ? json['completed_purchases_value']
          : double.tryParse(json['completed_purchases_value'].toString()) ?? 0.0,
      totalPayments: json['total_payments'] is double
          ? json['total_payments']
          : double.tryParse(json['total_payments'].toString()) ?? 0.0,
      currentBalance: json['current_balance'] is double
          ? json['current_balance']
          : double.tryParse(json['current_balance'].toString()) ?? 0.0,
      balanceStatus: json['balance_status']?.toString() ?? '',
      pendingItemsValue: json['pending_items_value'] is double
          ? json['pending_items_value']
          : double.tryParse(json['pending_items_value'].toString()) ?? 0.0,
      refundedItemsValue: json['refunded_items_value'] is double
          ? json['refunded_items_value']
          : double.tryParse(json['refunded_items_value'].toString()) ?? 0.0,
      ordersAwaitingPayment: json['orders_awaiting_payment'] is double
          ? json['orders_awaiting_payment']
          : double.tryParse(json['orders_awaiting_payment'].toString()) ?? 0.0,
      availableCapacity: json['available_capacity'] is double
          ? json['available_capacity']
          : double.tryParse(json['available_capacity'].toString()) ?? 0.0,
    );
  }
}

class StatusBreakdown {
  final int id;
  final String name;
  final int count;
  final double total;

  StatusBreakdown({
    required this.id,
    required this.name,
    required this.count,
    required this.total,
  });

  factory StatusBreakdown.fromJson(Map<String, dynamic> json) {
    return StatusBreakdown(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      count: json['count'] is int ? json['count'] : int.tryParse(json['count'].toString()) ?? 0,
      total: json['total'] is double
          ? json['total']
          : double.tryParse(json['total'].toString()) ?? 0.0,
    );
  }
}

class ItemsSummary {
  final int totalItems;
  final int pendingCount;
  final int completedCount;
  final int refundedCount;
  final List<StatusBreakdown> statusBreakdown;

  ItemsSummary({
    required this.totalItems,
    required this.pendingCount,
    required this.completedCount,
    required this.refundedCount,
    required this.statusBreakdown,
  });

  factory ItemsSummary.fromJson(Map<String, dynamic> json) {
    return ItemsSummary(
      totalItems: json['total_items'] is int
          ? json['total_items']
          : int.tryParse(json['total_items'].toString()) ?? 0,
      pendingCount: json['pending_count'] is int
          ? json['pending_count']
          : int.tryParse(json['pending_count'].toString()) ?? 0,
      completedCount: json['completed_count'] is int
          ? json['completed_count']
          : int.tryParse(json['completed_count'].toString()) ?? 0,
      refundedCount: json['refunded_count'] is int
          ? json['refunded_count']
          : int.tryParse(json['refunded_count'].toString()) ?? 0,
      statusBreakdown: (json['status_breakdown'] as List?)
              ?.map((item) => StatusBreakdown.fromJson(item))
              .toList() ?? [],
    );
  }
}

class StatementPayment {
  final int id;
  final int buyerId;
  final double amount;
  final double dinarConvert;
  final String sellerId;
  final String date;
  final String note;
  final String buyerName;

  StatementPayment({
    required this.id,
    required this.buyerId,
    required this.amount,
    required this.dinarConvert,
    required this.sellerId,
    required this.date,
    required this.note,
    required this.buyerName,
  });

  factory StatementPayment.fromJson(Map<String, dynamic> json) {
    return StatementPayment(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      buyerId: json['buyerid'] is int
          ? json['buyerid']
          : int.tryParse(json['buyerid'].toString()) ?? 0,
      amount: json['amount'] is double
          ? json['amount']
          : double.tryParse(json['amount'].toString()) ?? 0.0,
      dinarConvert: json['dinarconvert'] is double
          ? json['dinarconvert']
          : double.tryParse(json['dinarconvert'].toString()) ?? 0.0,
      sellerId: json['sellerid']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      buyerName: json['buyer_name']?.toString() ?? '',
    );
  }
}

class CustomerStatementData {
  final CustomerStatementCustomer customer;
  final FinancialSummary financialSummary;
  final ItemsSummary itemsSummary;
  final List<dynamic> pendingItems; // Using Order model
  final List<dynamic> completedItems;
  final List<dynamic> refundedItems;
  final List<StatementPayment> payments;

  CustomerStatementData({
    required this.customer,
    required this.financialSummary,
    required this.itemsSummary,
    required this.pendingItems,
    required this.completedItems,
    required this.refundedItems,
    required this.payments,
  });

  factory CustomerStatementData.fromJson(Map<String, dynamic> json) {
    return CustomerStatementData(
      customer: CustomerStatementCustomer.fromJson(json['customer']),
      financialSummary: FinancialSummary.fromJson(json['financial_summary']),
      itemsSummary: ItemsSummary.fromJson(json['items_summary']),
      pendingItems: json['pending_items'] as List? ?? [],
      completedItems: json['completed_items'] as List? ?? [],
      refundedItems: json['refunded_items'] as List? ?? [],
      payments: (json['payments'] as List?)
              ?.map((item) => StatementPayment.fromJson(item))
              .toList() ?? [],
    );
  }
}

