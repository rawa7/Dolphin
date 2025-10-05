class Currency {
  final int id;
  final String currencyName;
  final String currencySign;
  final String currencyCode;
  final double currencyConvert;

  Currency({
    required this.id,
    required this.currencyName,
    required this.currencySign,
    required this.currencyCode,
    required this.currencyConvert,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: int.parse(json['id'].toString()),
      currencyName: json['currencyname'] ?? '',
      currencySign: json['currencysign'] ?? '',
      currencyCode: json['currencycode'] ?? '',
      currencyConvert: double.parse(json['currencyconvert'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currencyname': currencyName,
      'currencysign': currencySign,
      'currencycode': currencyCode,
      'currencyconvert': currencyConvert,
    };
  }

  // Display format: "$" (USD)
  String get displayName => '$currencySign ($currencyCode)';
  
  // Full format: Dolar - $ (USD)
  String get fullDisplayName => '$currencyName - $currencySign ($currencyCode)';
}

