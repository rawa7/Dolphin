import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/website_model.dart';
import '../models/order_model.dart';
import '../models/currency_model.dart';
import '../models/profile_model.dart';
import '../models/shop_item_model.dart';
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
}

