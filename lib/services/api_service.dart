import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/website_model.dart';
import '../models/order_model.dart';
import '../models/currency_model.dart';
import '../models/profile_model.dart';
import '../models/shop_item_model.dart';

class ApiService {
  static const String baseUrl = 'https://dolphinshippingiq.com/api';

  // Login API call
  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    try {
      final url = Uri.parse('$baseUrl/login.php');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = User.fromJson(data['data']['user']);
        return {
          'success': true,
          'user': user,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Get websites API call
  static Future<Map<String, dynamic>> getWebsites() async {
    try {
      final url = Uri.parse('$baseUrl/websites.php');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final websitesList = data['data']['websites'] as List;
        final websites = websitesList
            .map((json) => Website.fromJson(json))
            .where((website) => website.isValid) // Filter valid websites only
            .toList();

        // Sort by order_id
        websites.sort((a, b) => a.orderId.compareTo(b.orderId));

        return {
          'success': true,
          'websites': websites,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load websites',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Get banners API call
  static Future<Map<String, dynamic>> getBanners(String customerId) async {
    try {
      final url = Uri.parse('$baseUrl/banner.php?customer_id=$customerId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return {
          'success': true,
          'banners': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load banners',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Get currencies API call
  static Future<Map<String, dynamic>> getCurrencies() async {
    try {
      final url = Uri.parse('$baseUrl/currencies.php');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final currenciesList = data['data']['currencies'] as List;
        final currencies = currenciesList
            .map((currency) => Currency.fromJson(currency))
            .toList();
        return {
          'success': true,
          'currencies': currencies,
          'count': data['data']['count'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch currencies',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Add order API call
  static Future<Map<String, dynamic>> addOrder({
    required int customerId,
    required String link,
    required String size,
    required int qty,
    required File imageFile,
    String? country,
    double? price,
    int? currencyId,
    String? color,
    String? note,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/add_order.php');
      var request = http.MultipartRequest('POST', url);

      // Add required fields
      request.fields['customer_id'] = customerId.toString();
      request.fields['link'] = link;
      request.fields['size'] = size;
      request.fields['qty'] = qty.toString();
      
      // Add optional fields
      if (country != null && country.isNotEmpty) {
        request.fields['country'] = country;
      }
      if (price != null) {
        request.fields['price'] = price.toString();
      }
      if (currencyId != null) {
        request.fields['currency_id'] = currencyId.toString();
      }
      if (color != null && color.isNotEmpty) {
        request.fields['color'] = color;
      }
      if (note != null && note.isNotEmpty) {
        request.fields['note'] = note;
      }

      // Add image file
      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();
      var multipartFile = http.MultipartFile(
        'product_image',
        imageStream,
        imageLength,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final order = Order.fromJson(data['data']['order']);
        return {
          'success': true,
          'order': order,
          'serial': data['data']['serial'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add order',
          'errors': data['errors'] ?? [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Get all orders for a customer
  static Future<Map<String, dynamic>> getOrders(int customerId) async {
    try {
      final url = Uri.parse('$baseUrl/orders.php?customer_id=$customerId');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final ordersList = data['data']['orders'] as List;
        final orders = ordersList.map((json) => Order.fromJson(json)).toList();

        final statusesList = data['data']['statuses'] as List;
        final statuses = statusesList.map((json) => OrderStatus.fromJson(json)).toList();

        final accountInfo = AccountInfo.fromJson(data['data']['account_info']);

        return {
          'success': true,
          'orders': orders,
          'statuses': statuses,
          'account_info': accountInfo,
          'orders_count': data['data']['orders_count'],
          'summary': data['data']['summary'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load orders',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Accept an order
  static Future<Map<String, dynamic>> acceptOrder({
    required int customerId,
    required int orderId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/accept_order.php');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customer_id': customerId,
          'order_id': orderId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to accept order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Reject an order
  static Future<Map<String, dynamic>> rejectOrder({
    required int customerId,
    required int orderId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/reject_order.php');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customer_id': customerId,
          'order_id': orderId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reject order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Get profile data
  static Future<Map<String, dynamic>> getProfile({
    required int customerId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/profile.php?customer_id=$customerId');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final profileData = ProfileData.fromJson(data['data']);
        return {
          'success': true,
          'message': data['message'],
          'data': profileData,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Get shop items
  static Future<Map<String, dynamic>> getShopItems({
    required int customerId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/shop.php?customer_id=$customerId');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['data'] != null) {
        final List<ShopItem> items = (data['data'] as List)
            .map((item) => ShopItem.fromJson(item))
            .toList();
        
        return {
          'success': true,
          'data': items,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch shop items',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }
}

