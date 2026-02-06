import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';
import '../models/website_model.dart';
import '../models/order_model.dart';
import '../models/currency_model.dart';
import '../models/profile_model.dart';
import '../models/shop_item_model.dart';
import '../models/shop_banner_model.dart';
import '../models/notification_model.dart';
import '../models/size_model.dart';
import '../models/currency_rate_model.dart';
import '../models/customer_statement_model.dart';
import '../models/delivery_status_model.dart';

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

  // Signup API call
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String phone,
    required String address,
    required String password,
    String? email,
    String? instagram,
    String? facebook,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/signup.php');
      final requestBody = {
        'name': name,
        'phone': phone,
        'address': address,
        'password': password,
      };
      
      // Add optional fields if provided
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }
      if (instagram != null && instagram.isNotEmpty) {
        requestBody['instagram'] = instagram;
      }
      if (facebook != null && facebook.isNotEmpty) {
        requestBody['facebook'] = facebook;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 201 || response.statusCode == 200) && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Change Password API call
  static Future<Map<String, dynamic>> changePassword({
    required String customerId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/change_password.php');
      final response = await http.post(
        url,
        body: {
          'customer_id': customerId,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Failed to change password',
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

  // Get Sizes
  static Future<Map<String, dynamic>> getSizes() async {
    try {
      final url = Uri.parse('$baseUrl/sizes.php');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final sizesList = data['data']['sizes'] as List;
        // Filter out sizes with empty names
        final sizes = sizesList
            .map((size) => Size.fromJson(size))
            .where((size) => size.name.trim().isNotEmpty)
            .toList();
        
        return {
          'success': true,
          'sizes': sizes,
          'count': sizes.length,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch sizes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Get currency rates
  static Future<Map<String, dynamic>> getCurrencyRates() async {
    try {
      final url = Uri.parse('$baseUrl/currency_rates.php');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final currencyRatesData = CurrencyRatesData.fromJson(data['data']);
        
        return {
          'success': true,
          'data': currencyRatesData,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch currency rates',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Get customer statement
  static Future<Map<String, dynamic>> getCustomerStatement({
    required int customerId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/customer_statement.php?customer_id=$customerId');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final statementData = CustomerStatementData.fromJson(data['data']);
        
        return {
          'success': true,
          'data': statementData,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch customer statement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Get delivery status
  static Future<Map<String, dynamic>> getDeliveryStatus({
    required int customerId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/delivery_status.php?customer_id=$customerId');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final deliveryStatus = DeliveryStatus.fromJson(data['data']);
        
        return {
          'success': true,
          'data': deliveryStatus,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch delivery status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Update delivery status
  static Future<Map<String, dynamic>> updateDeliveryStatus({
    required int customerId,
    required int deliveryStatus,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/delivery_status.php');
      final requestBody = {
        'customer_id': customerId,
        'delivery_status': deliveryStatus,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'] != null ? DeliveryStatus.fromJson(data['data']) : null,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update delivery status',
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
      print('🔵 ADD ORDER - URL: $url');
      
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

      print('🔵 ADD ORDER - Request Fields: ${request.fields}');

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
      print('🔵 ADD ORDER - Image File: ${imageFile.path.split('/').last}, Size: $imageLength bytes');

      // Send request
      print('🔵 ADD ORDER - Sending request...');
      var streamedResponse = await request.send();
      print('🔵 ADD ORDER - Response Status Code: ${streamedResponse.statusCode}');
      
      var response = await http.Response.fromStream(streamedResponse);
      print('🔵 ADD ORDER - Response Body: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        print('✅ ADD ORDER - Success!');
        final order = Order.fromJson(data['data']['order']);
        return {
          'success': true,
          'order': order,
          'serial': data['data']['serial'],
          'message': data['message'],
        };
      } else {
        print('❌ ADD ORDER - Failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add order',
          'errors': data['errors'] ?? [],
        };
      }
    } catch (e, stackTrace) {
      print('❌ ADD ORDER - Exception: $e');
      print('❌ ADD ORDER - Stack Trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error: $e',
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
    int? customerId,
  }) async {
    try {
      // Use customer_id if provided, otherwise use 0 for guests
      final custId = customerId ?? 0;
      final url = Uri.parse('$baseUrl/shop.php?customer_id=$custId');
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

  // Save FCM token to backend
  static Future<Map<String, dynamic>> saveFCMToken({
    required String token,
    required String customerId,
    String? platform,
    String? deviceId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/save_fcm.php');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Customer-Id': customerId,
        },
        body: jsonEncode({
          'token': token,
          'customer_id': int.tryParse(customerId),
          'platform': platform,
          'device_id': deviceId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Token saved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to save token',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get Shein product data from API
  static Future<Map<String, dynamic>> getSheinProduct(String url) async {
    try {
      // Clean and normalize the URL
      String cleanUrl = url.trim();
      
      // Remove any trailing slashes or whitespace
      cleanUrl = cleanUrl.replaceAll(RegExp(r'[\s]+$'), '');
      
      // Fix incomplete URLs (e.g., "goods-616166.ht" -> "goods-616166.html")
      if (cleanUrl.endsWith('.ht') && !cleanUrl.endsWith('.html')) {
        cleanUrl = '${cleanUrl}ml';
      }
      
      // Ensure URL is properly formatted
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        // If it's a mobile URL without protocol, add https
        if (cleanUrl.startsWith('m.shein.com') || cleanUrl.startsWith('www.shein.com')) {
          cleanUrl = 'https://$cleanUrl';
        } else {
          return {
            'success': false,
            'message': 'Invalid URL format. Please provide a complete Shein URL.',
          };
        }
      }
      
      // Convert mobile URLs to standard format that API expects
      // API expects: https://ar.shein.com/...-p-PRODUCTID.html
      // Mobile format: https://m.shein.com/goods-PRODUCTID.html
      if (cleanUrl.contains('m.shein.com/goods-')) {
        // Extract product ID from mobile URL format
        final productIdMatch = RegExp(r'goods-(\d+)').firstMatch(cleanUrl);
        if (productIdMatch != null) {
          final productId = productIdMatch.group(1);
          // Convert to standard format: https://ar.shein.com/product-p-PRODUCTID.html
          cleanUrl = 'https://ar.shein.com/product-p-$productId.html';
          print('📝 Converted mobile URL to standard format: $cleanUrl');
        }
      }
      
      // Also handle other mobile URL formats
      if (cleanUrl.contains('m.shein.com') && !cleanUrl.contains('-p-')) {
        // Try to extract product ID from various mobile URL patterns
        final patterns = [
          RegExp(r'goods-(\d+)'),
          RegExp(r'product-(\d+)'),
          RegExp(r'/(\d{6,})'),
        ];
        
        for (final pattern in patterns) {
          final match = pattern.firstMatch(cleanUrl);
          if (match != null) {
            final productId = match.group(1);
            cleanUrl = 'https://ar.shein.com/product-p-$productId.html';
            print('📝 Converted URL to standard format: $cleanUrl');
            break;
          }
        }
      }
      
      print('📤 Calling Shein API with URL: $cleanUrl');
      final apiUrl = Uri.parse('$baseUrl/shein_product.php?url=${Uri.encodeComponent(cleanUrl)}');
      print('📤 Full API URL: $apiUrl');
      
      final response = await http.get(
        apiUrl,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 30));

      print('📥 API Response Status: ${response.statusCode}');
      if (response.body.length > 500) {
        print('📥 API Response Body (first 500 chars): ${response.body.substring(0, 500)}...');
      } else {
        print('📥 API Response Body: ${response.body}');
      }

      if (response.statusCode != 200) {
        // Try to parse error message from response
        String errorMessage = 'API request failed with status ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }
        } catch (e) {
          // If parsing fails, use default message
          final responsePreview = response.body.length > 200 
              ? response.body.substring(0, 200) 
              : response.body;
          errorMessage = 'API request failed with status ${response.statusCode}. Response: $responsePreview';
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }

      final data = jsonDecode(response.body);
      
      // Debug: Print API response structure
      print('=== Shein API Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response keys: ${data?.keys.toList()}');
      print('Success: ${data?['success']}');
      print('Data type: ${data?['data']?.runtimeType}');
      if (data?['data'] != null) {
        if (data['data'] is Map) {
          print('Data keys: ${(data['data'] as Map).keys.toList()}');
        } else if (data['data'] is List) {
          print('Data[0] keys: ${(data['data'] as List).isNotEmpty ? (data['data'][0] as Map?)?.keys.toList() : "empty"}');
        }
      }
      print('========================');
      
      // Check if response has the expected structure
      if (data == null) {
        return {
          'success': false,
          'message': 'Invalid API response: null',
        };
      }

      if (data['success'] != true) {
        return {
          'success': false,
          'message': data['message']?.toString() ?? 'API returned unsuccessful response',
        };
      }

      // Check if data exists - it can be either a Map or a List
      if (data['data'] == null) {
        return {
          'success': false,
          'message': 'No product data found in API response',
        };
      }

      Map<String, dynamic>? detail;
      
      // Handle both response formats: Map or List
      if (data['data'] is Map) {
        // API returns data as a Map directly (new format)
        final productData = data['data'] as Map<String, dynamic>;
        
        print('📦 Data Map keys: ${productData.keys.toList()}');
        
        // Check if it has 'detail' key (nested structure)
        if (productData['detail'] != null && productData['detail'] is Map) {
          detail = productData['detail'] as Map<String, dynamic>;
          print('✅ Found detail in nested structure');
        } else if (productData.containsKey('goods_name') || productData.containsKey('goods_id')) {
          // The data itself is the detail object (flat structure)
          detail = productData;
          print('✅ Using data as detail (flat structure)');
        } else {
          // Try to find detail in data array if it exists
          if (productData.containsKey('data') && productData['data'] is List && (productData['data'] as List).isNotEmpty) {
            final firstItem = (productData['data'] as List)[0];
            if (firstItem is Map && firstItem['detail'] != null) {
              detail = firstItem['detail'] as Map<String, dynamic>;
              print('✅ Found detail in data array');
            }
          }
        }
      } else if (data['data'] is List && (data['data'] as List).isNotEmpty) {
        // API returns data as a List (old format)
        final productData = (data['data'] as List)[0] as Map<String, dynamic>?;
        
        if (productData == null) {
          return {
            'success': false,
            'message': 'Product data is null in API response',
          };
        }
        
        if (productData['detail'] != null) {
          detail = productData['detail'] as Map<String, dynamic>;
        } else {
          detail = productData;
        }
        print('✅ Using List format');
      } else {
        return {
          'success': false,
          'message': 'Invalid data format in API response',
        };
      }
      
      // Final check for detail
      if (detail == null) {
        print('⚠️ Could not find detail in API response');
        print('⚠️ Data type: ${data['data'].runtimeType}');
        if (data['data'] is Map) {
          print('⚠️ Data keys: ${(data['data'] as Map).keys.toList()}');
        }
        return {
          'success': false,
          'message': 'Product detail not found in API response',
        };
      }
      
      print('✅ Detail keys: ${detail.keys.toList()}');
      
      // Extract product information with null safety
      final extractedData = {
        'title': detail['goods_name']?.toString() ?? 
                 detail['productRelationID']?.toString() ?? 
                 detail['goods_name_en']?.toString() ?? 
                 '',
        'price': detail['salePrice']?['amount']?.toString() ?? 
                 detail['retailPrice']?['amount']?.toString() ?? 
                 '',
        'currency': detail['salePrice']?['currency']?.toString() ?? 
                    detail['retailPrice']?['currency']?.toString() ?? 
                    'USD',
        'images': <String>[],
        'size': '',
        'color': '',
      };
      
      // Extract images with null safety
      if (detail['goods_img'] != null) {
        String imgUrl = detail['goods_img'].toString();
        if (imgUrl.isNotEmpty) {
          if (!imgUrl.startsWith('http')) {
            imgUrl = 'https:$imgUrl';
          }
          extractedData['images'] = [imgUrl];
        }
      }
      
      if (detail['original_img'] != null) {
        String imgUrl = detail['original_img'].toString();
        if (imgUrl.isNotEmpty) {
          if (!imgUrl.startsWith('http')) {
            imgUrl = 'https:$imgUrl';
          }
          final imagesList = extractedData['images'] as List<String>;
          if (!imagesList.contains(imgUrl)) {
            imagesList.insert(0, imgUrl);
          }
        }
      }
      
      // Extract size and color from attributes with null safety
      if (detail['mainSaleAttribute'] != null && 
          detail['mainSaleAttribute'] is List && 
          (detail['mainSaleAttribute'] as List).isNotEmpty) {
        try {
          final mainAttr = (detail['mainSaleAttribute'] as List)[0] as Map<String, dynamic>;
          if (mainAttr['attr_name_en']?.toString() == 'Color') {
            extractedData['color'] = mainAttr['attr_value_en']?.toString() ?? 
                                     mainAttr['attr_value']?.toString() ?? '';
          }
        } catch (e) {
          print('Error extracting color: $e');
        }
      }
      
      if (detail['secondSaleAttributes'] != null && 
          detail['secondSaleAttributes'] is List && 
          (detail['secondSaleAttributes'] as List).isNotEmpty) {
        try {
          final sizeAttr = (detail['secondSaleAttributes'] as List).firstWhere(
            (attr) => (attr as Map<String, dynamic>)['attr_name_en']?.toString() == 'Size',
            orElse: () => <String, dynamic>{},
          ) as Map<String, dynamic>;
          
          if (sizeAttr.isNotEmpty && 
              sizeAttr['attr_value_list'] != null && 
              sizeAttr['attr_value_list'] is List && 
              (sizeAttr['attr_value_list'] as List).isNotEmpty) {
            final sizeList = sizeAttr['attr_value_list'] as List;
            if (sizeList.isNotEmpty) {
              final firstSize = sizeList[0] as Map<String, dynamic>;
              extractedData['size'] = firstSize['attr_value_en']?.toString() ?? 
                                     firstSize['attr_value']?.toString() ?? '';
            }
          }
        } catch (e) {
          print('Error extracting size: $e');
        }
      }
      
      return {
        'success': true,
        'data': extractedData,
      };
    } catch (e) {
      print('Error in getSheinProduct: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Helper method to download image from URL
  static Future<File?> _downloadImage(String imageUrl) async {
    try {
      print('Downloading image from: $imageUrl');
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Safari/537.36',
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
          'Referer': 'https://www.shein.com/',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'shein_product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        print('✅ Image saved to: ${file.path} (${response.bodyBytes.length} bytes)');
        return file;
      } else {
        print('⚠️ Image download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error downloading image: $e');
    }
    return null;
  }

  // Delete/Deactivate FCM token from backend
  static Future<Map<String, dynamic>> deleteFCMToken({
    String? token,
    String? customerId,
    String? deviceId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/delete_fcm.php');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (customerId != null) 'Customer-Id': customerId,
        },
        body: jsonEncode({
          if (token != null) 'token': token,
          if (customerId != null) 'customer_id': int.tryParse(customerId),
          if (deviceId != null) 'device_id': deviceId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Token deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete token',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get Notifications
  static Future<Map<String, dynamic>> getNotifications({
    required int customerId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/notifications.php?customer_id=$customerId&limit=$limit&offset=$offset');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          try {
            final notificationData = NotificationData.fromJson(data['data']);
            
            return {
              'success': true,
              'data': notificationData,
              'message': data['message'] ?? 'Notifications retrieved successfully',
            };
          } catch (parseError) {
            return {
              'success': false,
              'message': 'Error parsing notifications: $parseError',
            };
          }
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch notifications',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark Notification as Read
  static Future<Map<String, dynamic>> markNotificationAsRead({
    required int customerId,
    required int notificationId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/notifications.php?customer_id=$customerId');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'notification_id': notificationId.toString(),
          'action': 'mark_read',
        },
      );

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'Failed to mark notification as read',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark All Notifications as Read
  static Future<Map<String, dynamic>> markAllNotificationsAsRead({
    required int customerId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/notifications.php?customer_id=$customerId&mark_all_read=1');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'All notifications marked as read',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get Shop Banners
  static Future<Map<String, dynamic>> getShopBanners() async {
    try {
      final url = Uri.parse('$baseUrl/shop_banners.php');
      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
        final List<ShopBanner> banners = (data['data'] as List)
            .map((item) => ShopBanner.fromJson(item))
            .toList();
        
        return {
          'success': true,
          'data': banners,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch shop banners',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}

