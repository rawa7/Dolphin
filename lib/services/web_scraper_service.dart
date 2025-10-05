import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class WebScraperService {
  static Future<Map<String, dynamic>> fetchProductDetails(String url) async {
    try {
      // Validate URL
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      // Convert mobile URLs to desktop for better scraping
      url = _convertToDesktopUrl(url);

      final uri = Uri.parse(url);
      
      // Make HTTP request with better headers
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept-Encoding': 'gzip, deflate, br',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to load page. Status: ${response.statusCode}',
        };
      }

      // Parse HTML
      final document = html_parser.parse(response.body);

      // Extract product details
      final productData = _extractProductData(document, url);

      if (productData['images'].isEmpty) {
        return {
          'success': false,
          'message': 'Could not find product details on this page.',
        };
      }

      return {
        'success': true,
        'data': productData,
        'message': 'Product details fetched successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching product: ${e.toString()}',
      };
    }
  }

  static String _convertToDesktopUrl(String url) {
    // Convert SHEIN mobile to desktop
    if (url.contains('m.shein.com')) {
      url = url.replaceAll('m.shein.com', 'www.shein.com');
    }
    
    // Remove mobile parameters
    if (url.contains('?')) {
      final uri = Uri.parse(url);
      final cleanParams = <String, String>{};
      uri.queryParameters.forEach((key, value) {
        // Keep essential parameters only
        if (!key.contains('mobile') && !key.contains('src_') && !key.contains('page_')) {
          cleanParams[key] = value;
        }
      });
      if (cleanParams.isNotEmpty) {
        url = uri.replace(queryParameters: cleanParams).toString();
      } else {
        url = '${uri.scheme}://${uri.host}${uri.path}';
      }
    }
    
    return url;
  }

  static Map<String, dynamic> _extractProductData(Document document, String baseUrl) {
    Map<String, dynamic> data = {
      'title': null,
      'price': null,
      'currency': null,
      'images': <String>[],
      'description': null,
      'color': null,
      'size': null,
    };

    // Detect site type for specialized extraction
    final siteType = _detectSiteType(baseUrl);

    // Extract from Open Graph meta tags (most reliable)
    data['title'] = _getMetaContent(document, 'og:title') ?? 
                    _getMetaContent(document, 'twitter:title');
    
    data['description'] = _getMetaContent(document, 'og:description') ?? 
                          _getMetaContent(document, 'twitter:description');

    // Extract images from Open Graph
    String? ogImage = _getMetaContent(document, 'og:image') ?? 
                      _getMetaContent(document, 'twitter:image');
    if (ogImage != null) {
      data['images'].add(_makeAbsoluteUrl(ogImage, baseUrl));
    }

    // Extract price from Open Graph or schema
    data['price'] = _getMetaContent(document, 'og:price:amount') ?? 
                    _getMetaContent(document, 'product:price:amount');
    
    data['currency'] = _getMetaContent(document, 'og:price:currency') ?? 
                       _getMetaContent(document, 'product:price:currency');

    // Try to extract from JSON-LD schema
    final jsonLdData = _extractJsonLdData(document);
    if (jsonLdData != null) {
      data['title'] = data['title'] ?? jsonLdData['name'];
      data['description'] = data['description'] ?? jsonLdData['description'];
      if (jsonLdData['offers'] != null) {
        data['price'] = data['price'] ?? jsonLdData['offers']['price'];
        data['currency'] = data['currency'] ?? jsonLdData['offers']['priceCurrency'];
      }
      if (jsonLdData['image'] != null) {
        if (jsonLdData['image'] is List) {
          for (var img in jsonLdData['image']) {
            data['images'].add(_makeAbsoluteUrl(img.toString(), baseUrl));
          }
        } else {
          data['images'].add(_makeAbsoluteUrl(jsonLdData['image'].toString(), baseUrl));
        }
      }
    }

    // Site-specific extraction
    if (siteType == 'shein') {
      _extractSheinData(document, baseUrl, data);
    } else if (siteType == 'zara') {
      _extractZaraData(document, baseUrl, data);
    }

    // Fallback: Try common product image selectors
    if (data['images'].isEmpty) {
      _extractProductImages(document, baseUrl, data);
    }

    // Fallback: Try common price selectors
    if (data['price'] == null) {
      _extractPrice(document, data);
    }

    // Fallback: Try to get title from page title or h1
    if (data['title'] == null) {
      data['title'] = document.querySelector('h1')?.text.trim() ?? 
                      document.querySelector('title')?.text.trim();
    }

    // Extract color if available
    _extractColor(document, data);

    // Extract size if available
    _extractSize(document, data);

    return data;
  }

  static String _detectSiteType(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('shein.com')) return 'shein';
    if (lowerUrl.contains('zara.com')) return 'zara';
    if (lowerUrl.contains('trendyol.com')) return 'trendyol';
    if (lowerUrl.contains('amazon.')) return 'amazon';
    if (lowerUrl.contains('hm.com')) return 'hm';
    return 'generic';
  }

  static void _extractSheinData(Document document, String baseUrl, Map<String, dynamic> data) {
    // SHEIN uses specific data attributes and classes
    
    // Try to find product data in script tags
    final scripts = document.querySelectorAll('script');
    for (var script in scripts) {
      final text = script.text;
      
      // Look for product data in window objects
      if (text.contains('productIntroData') || text.contains('gbProductInfo')) {
        // Try to extract price
        final priceMatch = RegExp(r'"salePrice"[:\s]*\{[^}]*"amount"[:\s]*"?([0-9.]+)"?').firstMatch(text);
        if (priceMatch != null && data['price'] == null) {
          data['price'] = priceMatch.group(1);
        }
        
        // Try to extract currency
        final currencyMatch = RegExp(r'"code"[:\s]*"([A-Z]{3})"').firstMatch(text);
        if (currencyMatch != null && data['currency'] == null) {
          data['currency'] = currencyMatch.group(1);
        }
        
        // Try to extract images
        final imageMatches = RegExp(r'"origin_image"[:\s]*"([^"]+)"').allMatches(text);
        for (var match in imageMatches) {
          final img = match.group(1);
          if (img != null && !data['images'].contains(img)) {
            data['images'].add(img);
          }
        }
      }
    }
    
    // Fallback: Try data attributes
    final imgElements = document.querySelectorAll('[data-src*="shein"]');
    for (var img in imgElements) {
      final src = img.attributes['data-src'];
      if (src != null && !data['images'].contains(src)) {
        data['images'].add(src);
      }
    }
  }

  static void _extractZaraData(Document document, String baseUrl, Map<String, dynamic> data) {
    // Zara uses script tags with product data
    final scripts = document.querySelectorAll('script');
    for (var script in scripts) {
      final text = script.text;
      
      // Look for product data
      if (text.contains('window.zara') || text.contains('productData')) {
        // Extract price
        final priceMatch = RegExp(r'"price"[:\s]*([0-9]+)').firstMatch(text);
        if (priceMatch != null && data['price'] == null) {
          final price = priceMatch.group(1);
          if (price != null) {
            data['price'] = (int.parse(price) / 100).toString(); // Zara stores in cents
          }
        }
        
        // Extract images
        final imageMatches = RegExp(r'"url"[:\s]*"(https://[^"]*images[^"]*\.jpg[^"]*)"').allMatches(text);
        for (var match in imageMatches) {
          final img = match.group(1);
          if (img != null && !data['images'].contains(img)) {
            data['images'].add(img);
          }
        }
      }
    }
    
    // Try picture elements
    final pictures = document.querySelectorAll('picture img, [class*="image"] img');
    for (var img in pictures) {
      final src = img.attributes['src'] ?? img.attributes['data-src'];
      if (src != null && src.contains('images') && !data['images'].contains(src)) {
        data['images'].add(_makeAbsoluteUrl(src, baseUrl));
      }
    }
  }

  static String? _getMetaContent(Document document, String property) {
    // Try property attribute first
    var element = document.querySelector('meta[property="$property"]');
    if (element != null) {
      return element.attributes['content'];
    }
    
    // Try name attribute
    element = document.querySelector('meta[name="$property"]');
    if (element != null) {
      return element.attributes['content'];
    }
    
    return null;
  }

  static Map<String, dynamic>? _extractJsonLdData(Document document) {
    try {
      final scripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (var script in scripts) {
        final jsonText = script.text;
        if (jsonText.isEmpty) continue;
        
        final jsonData = jsonDecode(jsonText);
        
        // Handle array of LD+JSON objects
        if (jsonData is List) {
          for (var item in jsonData) {
            if (item is Map && item['@type'] == 'Product') {
              return Map<String, dynamic>.from(item);
            }
          }
        } else if (jsonData is Map) {
          if (jsonData['@type'] == 'Product') {
            return Map<String, dynamic>.from(jsonData);
          }
          // Sometimes it's nested
          if (jsonData['@graph'] != null) {
            for (var item in jsonData['@graph']) {
              if (item is Map && item['@type'] == 'Product') {
                return Map<String, dynamic>.from(item);
              }
            }
          }
        }
      }
    } catch (e) {
      // JSON parsing failed, continue
    }
    return null;
  }

  static void _extractProductImages(Document document, String baseUrl, Map<String, dynamic> data) {
    // Common product image selectors for various e-commerce platforms
    final imageSelectors = [
      'img[src*="product"]',
      'img[src*="image"]',
      'img[data-src*="product"]',
      '.product-image img',
      '.product-gallery img',
      '[data-image-role="product-image"]',
      '.gallery-image img',
      '#product-image',
      '[data-testid="product-image"]',
      '.product-photo img',
      '.main-image img',
      '[itemprop="image"]',
      '.product-img img',
      'picture img',
      '[class*="ProductImage"] img',
      '[class*="product-photo"] img',
    ];

    for (var selector in imageSelectors) {
      final images = document.querySelectorAll(selector);
      for (var img in images) {
        final src = img.attributes['src'] ?? 
                    img.attributes['data-src'] ?? 
                    img.attributes['data-lazy'] ??
                    img.attributes['data-original'];
        if (src != null && 
            src.isNotEmpty &&
            !src.contains('placeholder') && 
            !src.contains('loading') &&
            !src.contains('blank') &&
            !src.endsWith('.svg')) {
          final absoluteUrl = _makeAbsoluteUrl(src, baseUrl);
          if (!data['images'].contains(absoluteUrl) && 
              (absoluteUrl.endsWith('.jpg') || 
               absoluteUrl.endsWith('.jpeg') || 
               absoluteUrl.endsWith('.png') || 
               absoluteUrl.endsWith('.webp'))) {
            data['images'].add(absoluteUrl);
            if (data['images'].length >= 5) break; // Limit to 5 images
          }
        }
      }
      if (data['images'].isNotEmpty) break;
    }
  }

  static void _extractPrice(Document document, Map<String, dynamic> data) {
    // Common price selectors
    final priceSelectors = [
      '[data-price]',
      '[class*="price-sales"]',
      '[class*="price-now"]',
      '.price',
      '.product-price',
      '[itemprop="price"]',
      '.sale-price',
      '.current-price',
      '[data-testid="price"]',
      '.price-current',
      '#product-price',
      '[class*="Price"]',
      'span[class*="price"]',
    ];

    for (var selector in priceSelectors) {
      final priceElement = document.querySelector(selector);
      if (priceElement != null) {
        // First try data-price attribute
        final dataPrice = priceElement.attributes['data-price'];
        if (dataPrice != null && dataPrice.isNotEmpty) {
          data['price'] = dataPrice;
          continue;
        }
        
        final priceText = priceElement.text.trim();
        if (priceText.isEmpty) continue;
        
        // Extract numeric price (handle decimals and thousands separators)
        final priceMatch = RegExp(r'[\d,]+\.?\d*').firstMatch(priceText);
        if (priceMatch != null) {
          data['price'] = priceMatch.group(0)?.replaceAll(',', '');
          
          // Try to extract currency
          final currencyMatch = RegExp(r'[A-Z]{3}|\$|€|£|¥|₺|TL').firstMatch(priceText);
          if (currencyMatch != null) {
            final currencySymbol = currencyMatch.group(0);
            data['currency'] = _currencySymbolToCode(currencySymbol);
          }
          break;
        }
      }
    }
  }

  static void _extractColor(Document document, Map<String, dynamic> data) {
    final colorSelectors = [
      '.selected-color',
      '.color-name',
      '[data-attribute="color"]',
      '.product-color',
    ];

    for (var selector in colorSelectors) {
      final colorElement = document.querySelector(selector);
      if (colorElement != null) {
        data['color'] = colorElement.text.trim();
        break;
      }
    }
  }

  static void _extractSize(Document document, Map<String, dynamic> data) {
    final sizeSelectors = [
      '.selected-size',
      '.size-selected',
      '[data-attribute="size"]',
      '.product-size',
    ];

    for (var selector in sizeSelectors) {
      final sizeElement = document.querySelector(selector);
      if (sizeElement != null) {
        data['size'] = sizeElement.text.trim();
        break;
      }
    }
  }

  static String _makeAbsoluteUrl(String url, String baseUrl) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    try {
      final base = Uri.parse(baseUrl);
      if (url.startsWith('//')) {
        return '${base.scheme}:$url';
      }
      if (url.startsWith('/')) {
        return '${base.scheme}://${base.host}$url';
      }
      return '${base.scheme}://${base.host}/${base.pathSegments.join('/')}/$url';
    } catch (e) {
      return url;
    }
  }

  static String? _currencySymbolToCode(String? symbol) {
    if (symbol == null) return null;
    
    final currencyMap = {
      '\$': 'USD',
      '€': 'EUR',
      '£': 'GBP',
      '¥': 'JPY',
      '₺': 'TRY',
      'TL': 'TRY',
      'USD': 'USD',
      'EUR': 'EUR',
      'GBP': 'GBP',
    };
    
    return currencyMap[symbol] ?? symbol;
  }

  // Download image from URL
  static Future<http.Response?> downloadImage(String imageUrl) async {
    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return response;
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }
}

