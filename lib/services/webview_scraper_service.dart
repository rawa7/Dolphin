import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class WebViewScraperService {
  static Future<Map<String, dynamic>> fetchProductDetailsWithWebView(
    BuildContext context,
    String url,
  ) async {
    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => _InteractiveWebViewScraper(url: url),
        ),
      );

      if (result != null && result['success'] == true) {
        return result;
      }

      return {
        'success': false,
        'message': result?['message'] ?? 'Could not extract product details',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}

class _InteractiveWebViewScraper extends StatefulWidget {
  final String url;

  const _InteractiveWebViewScraper({required this.url});

  @override
  State<_InteractiveWebViewScraper> createState() => _InteractiveWebViewScraperState();
}

class _InteractiveWebViewScraperState extends State<_InteractiveWebViewScraper> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isExtracting = false;
  final GlobalKey _webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Convert app links to web URLs before loading
    final initialUrl = _convertAppLinkToWebUrl(widget.url);
    print('WebViewScraper: Loading URL: $initialUrl');
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Intercept app deep links and convert to web URLs
            final url = request.url.toLowerCase();
            if (url.startsWith('sheinlink://') || url.startsWith('shein://')) {
              final convertedUrl = _convertAppLinkToWebUrl(request.url);
              print('WebViewScraper: App link detected: ${request.url}');
              print('WebViewScraper: Converting to: $convertedUrl');
              
              // Load the converted URL instead
              _controller.loadRequest(Uri.parse(convertedUrl));
              return NavigationDecision.prevent;
            }
            
            // Allow all http/https URLs
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }
  
  // Convert app deep links to proper web URLs
  String _convertAppLinkToWebUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    print('=== URL Conversion Debug ===');
    print('Original URL: $url');
    
    // Handle Shein app links (sheinlink://applink/goods/ID or shein://...)
    if (lowerUrl.startsWith('sheinlink://') || lowerUrl.startsWith('shein://')) {
      // Extract product ID from the URL - try multiple patterns
      
      // Pattern 1: goods/12345 or goods_12345
      final goodsIdMatch = RegExp(r'goods[/_](\d+)', caseSensitive: false).firstMatch(url);
      if (goodsIdMatch != null) {
        final productId = goodsIdMatch.group(1);
        print('Pattern 1 matched - Product ID: $productId');
        // Use mobile-friendly URL
        final convertedUrl = 'https://m.shein.com/goods-$productId.html';
        print('Converted URL: $convertedUrl');
        return convertedUrl;
      }
      
      // Pattern 2: goods_id in data parameter
      final dataMatch = RegExp(r'goods_id.*?(\d{6,})', caseSensitive: false).firstMatch(url);
      if (dataMatch != null) {
        final productId = dataMatch.group(1);
        print('Pattern 2 matched - Product ID: $productId');
        final convertedUrl = 'https://m.shein.com/goods-$productId.html';
        print('Converted URL: $convertedUrl');
        return convertedUrl;
      }
      
      // Pattern 3: Any 6+ digit number
      final idMatch = RegExp(r'(\d{6,})').firstMatch(url);
      if (idMatch != null) {
        final productId = idMatch.group(1);
        print('Pattern 3 matched - Product ID: $productId');
        final convertedUrl = 'https://m.shein.com/goods-$productId.html';
        print('Converted URL: $convertedUrl');
        return convertedUrl;
      }
      
      print('No pattern matched! Returning original URL');
    }
    
    print('Not a shein link, returning original');
    print('===========================');
    return url;
  }

  Future<void> _extractData() async {
    if (_isExtracting) return;
    
    setState(() {
      _isExtracting = true;
    });

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Extracting product data...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Wait a bit more for any lazy-loaded content
      await Future.delayed(const Duration(seconds: 1));
      
      // JavaScript to extract product data
      final String script = '''
        (function() {
          var data = {
            title: null,
            price: null,
            currency: null,
            images: [],
            description: null,
            color: null
          };
          
          var host = window.location.hostname;
          
          // SHEIN specific - Extract from JavaScript object FIRST
          if (host.includes('shein')) {
            try {
              console.log('SHEIN detected, checking window.gbProductDetail...');
              // SHEIN stores data in window.gbProductDetail
              if (window.gbProductDetail && window.gbProductDetail.detail) {
                console.log('Found gbProductDetail.detail:', JSON.stringify(window.gbProductDetail.detail).substring(0, 500));
                
                // Get title
                if (window.gbProductDetail.detail.goods_name) {
                  data.title = window.gbProductDetail.detail.goods_name;
                  console.log('SHEIN title:', data.title);
                }
                
                // Get price from salePrice object
                if (window.gbProductDetail.detail.salePrice) {
                  data.price = window.gbProductDetail.detail.salePrice.amount || 
                              window.gbProductDetail.detail.salePrice.usdAmount;
                  data.currency = 'USD';
                  console.log('SHEIN price:', data.price, data.currency);
                }
                
                // Get images from goods_imgs
                if (window.gbProductDetail.detail.goods_imgs && 
                    window.gbProductDetail.detail.goods_imgs.detail_image) {
                  data.images = window.gbProductDetail.detail.goods_imgs.detail_image.slice(0, 5);
                  console.log('SHEIN images count:', data.images.length);
                }
              } else {
                console.log('window.gbProductDetail not found or no detail');
              }
            } catch(e) {
              console.log('SHEIN JS extraction error:', e);
            }
          }
          
          // Generic DOM extraction as fallback (if no data found yet)
          if (!data.title) {
            var titleEl = document.querySelector('h1, [class*="product-name"], [class*="product-title"], [class*="ProductTitle"], [class*="goods-name"], [data-testid*="product-title"], .product-intro__head-name');
            if (titleEl) data.title = titleEl.innerText.trim();
          }
          
          if (!data.price) {
            var priceEls = document.querySelectorAll('[class*="price"], [class*="Price"], [data-price], .product-intro__head-price');
            for (var el of priceEls) {
              var text = el.innerText || el.textContent || el.getAttribute('data-price') || '';
              var match = text.match(/[\$€£₺]?\\s*[0-9,]+\\.?[0-9]*/);
              if (match && match[0].length > 0) {
                var priceNum = match[0].replace(/[^0-9.]/g, '');
                if (priceNum && parseFloat(priceNum) > 1) {  // Must be > 1 to avoid ratings
                  data.price = priceNum;
                  // Try to get currency
                  if (text.includes('\$') || text.includes('USD')) data.currency = 'USD';
                  else if (text.includes('€') || text.includes('EUR')) data.currency = 'EUR';
                  else if (text.includes('£') || text.includes('GBP')) data.currency = 'GBP';
                  else if (text.includes('₺') || text.includes('TL') || text.includes('TRY')) data.currency = 'TRY';
                  break;
                }
              }
            }
          }
          
          if (data.images.length === 0) {
            var imgs = document.querySelectorAll('img');
            var imageSet = new Set();
            for (var img of imgs) {
              var src = img.src || img.getAttribute('data-src') || img.getAttribute('data-original');
              if (src && src.includes('http') && 
                  (src.includes('product') || src.includes('image') || src.includes('media') || 
                   src.includes('static') || src.includes('cdn'))) {
                if (!src.includes('placeholder') && !src.includes('blank') && 
                    !src.includes('loading') && !src.endsWith('.svg') &&
                    (src.includes('.jpg') || src.includes('.jpeg') || 
                     src.includes('.png') || src.includes('.webp'))) {
                  imageSet.add(src);
                  if (imageSet.size >= 5) break;
                }
              }
            }
            data.images = Array.from(imageSet);
          }
          
          // Zara specific
          if (host.includes('zara')) {
            try {
              // Zara may have data in window.__INITIAL_STATE__ or similar
              var scripts = document.querySelectorAll('script');
              for (var script of scripts) {
                if (script.textContent && script.textContent.includes('price')) {
                  var match = script.textContent.match(/"price"\\s*:\\s*([0-9]+)/);
                  if (match) {
                    data.price = (parseInt(match[1]) / 100).toFixed(2);
                  }
                }
              }
            } catch(e) {}
          }
          
          // Amazon specific
          if (host.includes('amazon')) {
            try {
              var priceEl = document.querySelector('.a-price-whole, .a-price-range');
              if (priceEl) {
                data.price = priceEl.innerText.replace(/[^0-9.]/g, '');
              }
              var titleEl = document.querySelector('#productTitle');
              if (titleEl) {
                data.title = titleEl.innerText.trim();
              }
            } catch(e) {}
          }
          
          return JSON.stringify(data);
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      String jsonString = result.toString();
      
      // Debug: Print raw result
      print('=== Raw JavaScript Result ===');
      print('Length: ${jsonString.length}');
      print('First 200 chars: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}');
      print('=============================');
      
      // The result comes back as a string that might be double-encoded
      // If it starts and ends with quotes, it's a JSON string within a string
      if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
        // Remove outer quotes
        jsonString = jsonString.substring(1, jsonString.length - 1);
        // Unescape ONLY the quotes - keep other escape sequences as-is
        // This preserves \n, \r, \t as valid JSON escape sequences
        jsonString = jsonString.replaceAll(r'\"', '"');
      }
      
      // Debug: Print cleaned JSON
      print('=== Cleaned JSON ===');
      print('Length: ${jsonString.length}');
      print('First 200 chars: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}');
      print('====================');
      
      final data = jsonDecode(jsonString);
      
      // Clean up the title - remove ratings and extra whitespace
      if (data['title'] != null) {
        String title = data['title'].toString();
        // Remove ratings like "\n\n5.00\n\n(9)" at the end (handles both literal \n and actual newlines)
        title = title.replaceAll(RegExp(r'(\\n|\n)+\d+\.\d+(\\n|\n)+\(\d+\)$'), '');
        // Remove multiple newlines (both literal and actual)
        title = title.replaceAll(RegExp(r'(\\n|\n)+'), ' ');
        // Remove multiple spaces
        title = title.replaceAll(RegExp(r'\s+'), ' ');
        // Trim whitespace
        title = title.trim();
        data['title'] = title;
      }
      
      // Debug: Print what we found
      print('=== Extracted Data ===');
      print('Title: ${data['title']}');
      print('Price: ${data['price']}');
      print('Currency: ${data['currency']}');
      print('Images: ${data['images']?.length ?? 0}');
      print('====================');

      // Check if we got any useful data
      if ((data['images'] != null && data['images'].isNotEmpty) || 
          (data['price'] != null && data['price'].toString().isNotEmpty) || 
          (data['title'] != null && data['title'].toString().isNotEmpty)) {
        
        // ALWAYS take screenshot to capture what user sees
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
              content: Text('Taking screenshot...'),
                duration: Duration(seconds: 1),
              ),
            );
          }
          
          // Wait a moment for snackbar to show
          await Future.delayed(const Duration(milliseconds: 500));
          
        // Take screenshot
        File? imageFile = await _captureScreenshot();
          
          if (imageFile != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Screenshot captured successfully!'),
                duration: Duration(seconds: 1),
              ),
            );
        }

        setState(() {
          _isExtracting = false;
        });

        if (mounted) {
          print('=== Returning Data from WebViewScraper ===');
          print('Screenshot file: ${imageFile?.path ?? "NULL"}');
          print('Data keys: ${data.keys.toList()}');
          print('==========================================');
          
          Navigator.pop(context, {
            'success': true,
            'data': {
              ...data,
              'imageFile': imageFile,
            },
            'message': imageFile != null 
                ? 'Product details extracted successfully'
                : 'Data extracted. Please upload a product image manually.',
          });
        }
      } else {
        // No data found at all, offer to take screenshot
        setState(() {
          _isExtracting = false;
        });
        
        if (mounted) {
          _showScreenshotDialog();
        }
      }
    } catch (e) {
      setState(() {
        _isExtracting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        _showScreenshotDialog();
      }
    }
  }

  void _showScreenshotDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Extract Data'),
        content: const Text(
          'Could not automatically extract product details.\n\n'
          'Wait for the page to fully load, then try again.\n'
          'Or take a screenshot to use as the product image.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(this.context, {
                'success': false,
                'message': 'Extraction cancelled',
              });
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Reset state and allow user to try again
              setState(() {
                _isExtracting = false;
              });
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _takeScreenshot();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Screenshot'),
          ),
        ],
      ),
    );
  }

  Future<void> _takeScreenshot() async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Taking screenshot...')),
        );
      }

      // Wait a moment for the snackbar to show
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to get screenshot from WebView (this might not work on all platforms)
      // So we'll use a fallback method
      final imageFile = await _captureScreenshot();

      if (mounted && imageFile != null) {
        Navigator.pop(context, {
          'success': true,
          'data': {
            'title': null,
            'price': null,
            'currency': null,
            'images': [],
            'imageFile': imageFile,
          },
          'message': 'Screenshot captured. Please fill in the details manually.',
        });
      } else {
        if (mounted) {
          Navigator.pop(context, {
            'success': false,
            'message': 'Could not take screenshot. Please enter details manually.',
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, {
          'success': false,
          'message': 'Screenshot failed: ${e.toString()}',
        });
      }
    }
  }

  Future<File?> _captureScreenshot() async {
    try {
      print('Capturing screenshot...');
      
      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');

      // Try to get screenshot using RenderRepaintBoundary with high quality
      final RenderObject? renderObject = _webViewKey.currentContext?.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        print('RenderRepaintBoundary found, capturing with pixelRatio: 3.0');
        final ui.Image image = await renderObject.toImage(pixelRatio: 3.0); // Higher quality
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData != null) {
          await file.writeAsBytes(byteData.buffer.asUint8List());
          print('Screenshot saved: ${file.path}, size: ${byteData.lengthInBytes} bytes');
          return file;
        } else {
          print('ByteData is null');
        }
      } else {
        print('RenderObject is not a RenderRepaintBoundary');
      }

      return null;
    } catch (e) {
      print('Screenshot error: $e');
      return null;
    }
  }

  Future<File?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Page'),
        backgroundColor: Colors.pink[700],
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && !_isExtracting)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
              tooltip: 'Reload',
            ),
        ],
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: _webViewKey,
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: _isLoading || _isExtracting
          ? null
          : FloatingActionButton.extended(
              onPressed: _extractData,
              backgroundColor: Colors.pink[700],
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Get Data',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
