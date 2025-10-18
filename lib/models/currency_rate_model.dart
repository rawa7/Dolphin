class CurrencyRate {
  final int id;
  final String name;
  final String symbol;
  final String code;
  final double conversionRate;

  CurrencyRate({
    required this.id,
    required this.name,
    required this.symbol,
    required this.code,
    required this.conversionRate,
  });

  factory CurrencyRate.fromJson(Map<String, dynamic> json) {
    return CurrencyRate(
      id: json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0),
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      conversionRate: json['conversion_rate'] is double 
          ? json['conversion_rate'] 
          : (json['conversion_rate'] != null ? double.tryParse(json['conversion_rate'].toString()) ?? 1.0 : 1.0),
    );
  }
}

class CurrencyRatesData {
  final List<CurrencyRate> currencies;
  final int count;
  final String lastUpdated;

  CurrencyRatesData({
    required this.currencies,
    required this.count,
    required this.lastUpdated,
  });

  factory CurrencyRatesData.fromJson(Map<String, dynamic> json) {
    return CurrencyRatesData(
      currencies: (json['currencies'] as List?)
              ?.map((item) => CurrencyRate.fromJson(item))
              .toList() ?? [],
      count: json['count'] is int ? json['count'] : (json['count'] != null ? int.tryParse(json['count'].toString()) ?? 0 : 0),
      lastUpdated: json['last_updated']?.toString() ?? '',
    );
  }
}

