import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/app_colors.dart';
import '../utils/auth_helper.dart';
import '../services/api_service.dart';
import 'add_order_screen.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _isFetchingData = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  final GlobalKey _webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  
  Future<void> _addToOrder() async {
    // Check if user is logged in first
    final isAuthenticated = await AuthHelper.requireAuth(context);
    if (!isAuthenticated) {
      return; // User cancelled or not logged in
    }

    setState(() {
      _isFetchingData = true;
    });

    try {
      // Get current URL
      final currentUrl = await _controller.currentUrl() ?? widget.url;
      
      Map<String, dynamic>? extractedData;
      
      // Check if it's a Shein link - use API for Shein
      if (_isSheinUrl(currentUrl)) {
        print('🔍 Detected Shein URL, using API...');
        final apiResult = await ApiService.getSheinProduct(currentUrl);
        
        if (apiResult['success'] == true && apiResult['data'] != null) {
          extractedData = apiResult['data'] as Map<String, dynamic>;
          
          // Take screenshot for image
          try {
            final screenshot = await _captureScreenshot();
            if (screenshot != null) {
              extractedData['screenshot'] = screenshot.path;
            }
          } catch (e) {
            print('Screenshot failed: $e');
          }
        } else {
          print('⚠️ Shein API failed, falling back to webview extraction...');
          // Fallback to webview extraction
          extractedData = await _extractDataFromWebView();
        }
      } else {
        // For non-Shein sites, use webview extraction
        extractedData = await _extractDataFromWebView();
      }
      
      setState(() {
        _isFetchingData = false;
      });

      if (extractedData == null) {
        // If extraction failed, show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not extract product data. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Navigate to Add Order screen with extracted data
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddOrderScreen(
              initialData: extractedData,
              initialUrl: currentUrl,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isFetchingData = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Check if URL is a Shein link
  bool _isSheinUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('shein.com') || 
           lowerUrl.contains('sheinlink://') || 
           lowerUrl.startsWith('shein://');
  }
  
  Future<Map<String, dynamic>?> _extractDataFromWebView() async {
    try {
      // JavaScript to extract product data directly from the current page
      const jsCode = '''
        (function() {
          try {
            console.log('SHEIN detected, checking window.gbProductDetail...');
            const data = {};
            
            // SHEIN-specific extraction
            if (typeof window.gbProductDetail !== 'undefined' && window.gbProductDetail && window.gbProductDetail.detail) {
              const detail = window.gbProductDetail.detail;
              console.log('Found gbProductDetail:', detail);
              
              data.title = detail.goods_name || detail.productRelationID || '';
              data.price = detail.salePrice?.amount || detail.retailPrice?.amount || '';
              data.currency = detail.salePrice?.currency || detail.retailPrice?.currency || 'USD';
              
              // Get SHEIN images - prioritize main product image
              const images = [];
              
              // Priority 1: goods_img (main product display image)
              if (detail.goods_img) {
                images.push(detail.goods_img);
              }
              
              // Priority 2: First image from goods_imgs array (usually main image)
              if (detail.goods_imgs && Array.isArray(detail.goods_imgs) && detail.goods_imgs.length > 0) {
                const firstImg = detail.goods_imgs[0];
                if (firstImg.origin_image && !images.includes(firstImg.origin_image)) {
                  images.push(firstImg.origin_image);
                }
                // Add remaining images
                detail.goods_imgs.slice(1).forEach(img => {
                  if (img.origin_image && !images.includes(img.origin_image)) {
                    images.push(img.origin_image);
                  }
                });
              }
              
              // Priority 3: detail_image (alternative view)
              if (detail.detail_image && !images.includes(detail.detail_image)) {
                images.push(detail.detail_image);
              }
              
              data.images = images;
              
              // Get selected size and color from our custom variables
              data.size = window.dolphinSelectedSize || '';
              data.color = window.dolphinSelectedColor || '';
              
              return JSON.stringify(data);
            }
            
            console.log('window.gbProductDetail not found or no detail');
            
            // Generic extraction for non-SHEIN sites
            data.title = document.querySelector('meta[property="og:title"]')?.content ||
                        document.querySelector('meta[name="twitter:title"]')?.content ||
                        document.querySelector('h1')?.textContent ||
                        document.title;
            
            // Try to get price
            const priceElement = document.querySelector('[class*="price"]') ||
                                document.querySelector('[itemprop="price"]') ||
                                document.querySelector('[data-price]');
            data.price = priceElement?.textContent?.match(/[\\d,.]+/)?.[0] || '';
            
            // Try to get currency
            const currencyElement = document.querySelector('[itemprop="priceCurrency"]');
            data.currency = currencyElement?.content || 
                           priceElement?.textContent?.match(/[A-Z]{3}/)?.[0] ||
                           document.querySelector('[class*="currency"]')?.textContent || '';
            
            // Try to get images - prioritize main product image
            const images = [];
            
            // Priority 1: Meta og:image (usually main product image - most reliable)
            const ogImage = document.querySelector('meta[property="og:image"]')?.content;
            if (ogImage && !images.includes(ogImage)) {
              images.push(ogImage);
            }
            
            // Priority 2: Twitter image (backup)
            const twitterImage = document.querySelector('meta[name="twitter:image"]')?.content;
            if (twitterImage && !images.includes(twitterImage)) {
              images.push(twitterImage);
            }
            
            // Priority 3: Specific product image selectors (most reliable for main image)
            const mainProductImageSelectors = [
              // Trendyol specific
              'img[class*="product-image"]',
              'img[class*="ProductImage"]',
              '[class*="productImage"] img',
              '[class*="product-image"] img',
              '[data-testid*="product-image"] img',
              '[data-testid*="productImage"] img',
              '.product-image img',
              '.productImage img',
              // Generic selectors
              'img[data-zoom-image]', // Zoom images are usually main product
              'img[itemprop="image"]', // Schema.org markup
              '.product-main-image img:first-child',
              '.product-image-container img:first-child',
              'img[class*="mainImage"]',
              'img[id*="mainImage"]',
              'img[class*="main-image"]',
              'img[id*="main-image"]',
              '[class*="ImageViewer"] img:first-child',
              '[class*="ProductImage"] img:first-child',
              'img[class*="productImage"]:first-child',
              '.gallery img:first-child',
              '[class*="product-gallery"] img:first-child',
              // Additional generic selectors
              'picture img',
              '[class*="slider"] img:first-child',
              '[class*="carousel"] img:first-child',
              '[class*="gallery"] img:first-child'
            ];
            
            for (const selector of mainProductImageSelectors) {
              try {
              const img = document.querySelector(selector);
                if (img) {
                  // Try multiple attributes for image source
                  const src = img.src || img.getAttribute('data-src') || img.getAttribute('data-lazy-src') || img.getAttribute('data-original');
                  if (src && src.trim() && !images.includes(src) && !src.includes('placeholder') && !src.includes('loading')) {
                    images.push(src);
                    break; // Found main image, stop searching
                  }
                }
              } catch (e) {
                // Continue to next selector
              }
            }
            
            // Priority 4: Additional product images (only if we found main image)
            if (images.length > 0) {
              const additionalImageSelectors = [
                'img[class*="productImage"]',
                'img[class*="product-image"]',
                'img[class*="ProductImage"]',
                '[class*="productImage"] img',
                '[class*="product-image"] img'
              ];
            
              for (const selector of additionalImageSelectors) {
                try {
                  const imgs = document.querySelectorAll(selector);
                  imgs.forEach(img => {
                    const src = img.src || img.getAttribute('data-src') || img.getAttribute('data-lazy-src');
                    if (src && src.trim() && !images.includes(src) && !src.includes('placeholder')) {
                      images.push(src);
                    }
                  });
                } catch (e) {
                  // Continue
                }
              }
            }
            
            data.images = images;
            
            // Try to get color (use our custom variable first, then fallback)
            data.color = window.dolphinSelectedColor || '';
            if (!data.color) {
            const colorElement = document.querySelector('[class*="color"] [class*="selected"]') ||
                                document.querySelector('[data-color]');
            data.color = colorElement?.textContent?.trim() || '';
            }
            
            // Try to get size (use our custom variable first, then fallback)
            data.size = window.dolphinSelectedSize || '';
            if (!data.size) {
            const sizeElement = document.querySelector('[class*="size"] [class*="selected"]') ||
                               document.querySelector('[data-size]');
            data.size = sizeElement?.textContent?.trim() || '';
            }
            
            return JSON.stringify(data);
          } catch (error) {
            return JSON.stringify({error: error.toString()});
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      
      if (result == null || result.toString().isEmpty) {
        return null;
      }

      // Parse the JSON result
      String jsonString = result.toString();
      
      // Remove outer quotes if present
      if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
        jsonString = jsonString.substring(1, jsonString.length - 1);
        jsonString = jsonString.replaceAll(r'\"', '"');
      }
      
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      // Clean up the title
      if (data['title'] != null) {
        String title = data['title'].toString();
        title = title.replaceAll(RegExp(r'(\\n|\n)+\d+\.\d+(\\n|\n)+\(\d+\)$'), '');
        title = title.replaceAll(RegExp(r'(\\n|\n)+'), ' ');
        title = title.replaceAll(RegExp(r'\s+'), ' ');
        title = title.trim();
        data['title'] = title;
      }
      
      // Clean up price
      if (data['price'] != null && data['price'].toString().isNotEmpty) {
        final priceStr = data['price'].toString().replaceAll(',', '');
        data['price'] = priceStr;
      }
      
      // ALWAYS take a screenshot to capture what user sees
      File? imageFile;
      try {
        print('Taking screenshot to capture product image...');
        imageFile = await _captureScreenshot();
          if (imageFile != null) {
          print('Screenshot captured successfully: ${imageFile.path}');
          } else {
          print('Screenshot returned null');
        }
      } catch (e) {
        print('Error capturing screenshot: $e');
      }
      
      // If no images found from JavaScript extraction, ensure we use screenshot
      if ((data['images'] == null || (data['images'] as List).isEmpty) && imageFile != null) {
        print('⚠️ No images found from JavaScript, using screenshot as fallback');
        // Screenshot will be used via imageFile
      }
      
      // Add the image file to data if we have one (always prioritize screenshot for accuracy)
      if (imageFile != null) {
        data['imageFile'] = imageFile;
        data['screenshot'] = imageFile.path; // Also add as screenshot for compatibility
        print('✅ Screenshot added to data: ${imageFile.path}');
        print('✅ Data keys: ${data.keys.toList()}');
        print('✅ Images from JS: ${data['images']}');
      } else {
        print('❌ No screenshot captured, imageFile is null');
        // If no screenshot and no images, try to use the first image URL
        if (data['images'] != null && (data['images'] as List).isNotEmpty) {
          print('✅ Using first image from JavaScript extraction: ${(data['images'] as List)[0]}');
        }
      }
      
      return data;
    } catch (e) {
      print('Error extracting data from WebView: $e');
      return null;
    }
  }
  
  Future<File?> _captureScreenshot() async {
    try {
      print('Capturing webview screenshot...');
      
      // Scroll to top first to show product image
      await _controller.runJavaScript('window.scrollTo(0, 0);');
      await Future.delayed(const Duration(milliseconds: 500)); // Wait for scroll
      
      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');

      // Get screenshot using RenderRepaintBoundary
      final RenderObject? renderObject = _webViewKey.currentContext?.findRenderObject();
      if (renderObject is RenderRepaintBoundary) {
        print('Capturing with pixelRatio: 3.0 for high quality');
        final ui.Image image = await renderObject.toImage(pixelRatio: 3.0); // High quality
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

  void _initializeWebView() {
    // Convert initial URL if it's an app link
    final initialUrl = _convertAppLinkToWebUrl(widget.url);
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Intercept app deep links and convert to web URLs
            final url = request.url.toLowerCase();
            if (url.startsWith('sheinlink://') || url.startsWith('shein://')) {
              final convertedUrl = _convertAppLinkToWebUrl(request.url);
              print('App link detected: ${request.url}');
              print('Converting to: $convertedUrl');
              
              // Load the converted URL instead
              _controller.loadRequest(Uri.parse(convertedUrl));
              return NavigationDecision.prevent;
            }
            
            // Allow all http/https URLs
            return NavigationDecision.navigate;
          },
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
            _updateNavigationState();
            
            // Set a timeout for page loading
            Future.delayed(const Duration(seconds: 30), () {
              if (_isLoading && mounted) {
                print('Page load timeout!');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Page is taking too long to load. Try refreshing.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            });
          },
          onPageFinished: (String url) async {
            print('Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
            // Update navigation buttons state
            _updateNavigationState();
            
            // Check if page loaded correctly
            try {
              final title = await _controller.getTitle();
              print('Page title: $title');
              
              // Check if it's a Shein error page
              if (url.toLowerCase().contains('shein.com')) {
                // Check if page shows error
                final bodyText = await _controller.runJavaScriptReturningResult(
                  "document.body.innerText.toLowerCase()"
                );
                
                final bodyTextStr = bodyText.toString().toLowerCase();
                if (bodyTextStr.contains('oops') || bodyTextStr.contains('can\'t find') || 
                    bodyTextStr.contains('not found') || bodyTextStr.contains('404')) {
                  print('⚠️ Shein error page detected! Trying alternative URL format...');
                  
                  // Try to extract product ID from current URL and try different format
                  final productIdMatch = RegExp(r'(\d{6,})').firstMatch(url);
                  if (productIdMatch != null) {
                    final productId = productIdMatch.group(1);
                    // Try a different URL format
                    final alternativeUrl = 'https://us.shein.com/pdsearch/$productId/';
                    print('Trying alternative URL: $alternativeUrl');
                    _controller.loadRequest(Uri.parse(alternativeUrl));
                    return;
                  }
                }
                
                // If page loaded successfully, inject custom CSS and JS
                await _customizeSheinPage();
              }
            } catch (e) {
              print('Error in onPageFinished: $e');
            }
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading page: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }
  
  // Convert app deep links to proper web URLs
  String _convertAppLinkToWebUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    print('=== WebView URL Conversion ===');
    print('Original URL: $url');
    print('Platform: ${Platform.operatingSystem}');
    
    // Handle Shein app links (sheinlink://applink/goods/ID or shein://...)
    if (lowerUrl.startsWith('sheinlink://') || lowerUrl.startsWith('shein://')) {
      // Extract product ID from the URL - try multiple patterns
      
      // Pattern 1: goods/12345 or goods_12345
      final goodsIdMatch = RegExp(r'goods[/_](\d+)', caseSensitive: false).firstMatch(url);
      if (goodsIdMatch != null) {
        final productId = goodsIdMatch.group(1);
        print('Pattern 1 matched - Product ID: $productId');
        
        // Use US Shein URL format which works more reliably
        final convertedUrl = 'https://us.shein.com/pdsearch/$productId/';
        print('Converted URL: $convertedUrl');
        return convertedUrl;
      }
      
      // Pattern 2: goods_id in data parameter
      final dataMatch = RegExp(r'goods_id.*?(\d{6,})', caseSensitive: false).firstMatch(url);
      if (dataMatch != null) {
        final productId = dataMatch.group(1);
        print('Pattern 2 matched - Product ID: $productId');
        final convertedUrl = 'https://us.shein.com/pdsearch/$productId/';
        print('Converted URL: $convertedUrl');
        return convertedUrl;
      }
      
      // Pattern 3: Any 6+ digit number
      final idMatch = RegExp(r'(\d{6,})').firstMatch(url);
      if (idMatch != null) {
        final productId = idMatch.group(1);
        print('Pattern 3 matched - Product ID: $productId');
        final convertedUrl = 'https://us.shein.com/pdsearch/$productId/';
        print('Converted URL: $convertedUrl');
        return convertedUrl;
      }
      
      print('No pattern matched!');
    }
    
    print('==============================');
    return url;
  }

  Future<void> _updateNavigationState() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }
  
  // Customize Shein page to hide their add to cart and enhance UX
  Future<void> _customizeSheinPage() async {
    try {
      const jsCode = '''
        (function() {
          try {
            // Inject CSS to hide Shein's add to cart and other UI elements
            const style = document.createElement('style');
            style.innerHTML = `
              /* Hide Shein's add to cart button */
              [class*="addToCart"],
              [class*="add-to-cart"],
              [class*="AddToCart"],
              button[class*="add"][class*="bag"],
              button[class*="Add"][class*="Bag"],
              .she-btn-black,
              [class*="buyNow"],
              [class*="buy-now"],
              
              /* Hide bottom sticky bar with cart */
              [class*="sticky-wrapper"],
              [class*="product-intro__footer"],
              [class*="goods-bottom-bar"],
              [class*="bottomBar"],
              [class*="bottom-bar"],
              
              /* Hide cart icon and wishlist in header */
              [class*="cart-icon"],
              [class*="wishlist"],
              [class*="favorite"],
              
              /* Hide promotional banners */
              [class*="promotion-bar"],
              [class*="promo-banner"],
              
              /* Hide chat/customer service */
              [class*="customer-service"],
              [class*="chat-btn"],
              [class*="live-chat"] {
                display: none !important;
                visibility: hidden !important;
                opacity: 0 !important;
                pointer-events: none !important;
              }
              
              /* Make product details more visible */
              [class*="product-intro__container"] {
                padding-bottom: 80px !important;
              }
              
              /* Ensure size selector is visible at top */
              [class*="size-select"],
              [class*="product-intro__attr-item"] {
                position: relative !important;
                z-index: 1 !important;
              }
            `;
            document.head.appendChild(style);
            
            // Store selected size globally for easy access
            window.dolphinSelectedSize = null;
            window.dolphinSelectedColor = null;
            
            // Function to capture selected size and color
            function captureSelections() {
              // Capture size
              const sizeSelected = document.querySelector('[class*="size"][class*="select"] [class*="active"]') ||
                                  document.querySelector('[class*="product-intro__attr-item"][class*="active"]');
              if (sizeSelected) {
                window.dolphinSelectedSize = sizeSelected.textContent?.trim();
              }
              
              // Capture color
              const colorSelected = document.querySelector('[class*="color"][class*="select"] [class*="active"]') ||
                                   document.querySelector('[class*="product-intro__sku-color"][class*="active"]');
              if (colorSelected) {
                window.dolphinSelectedColor = colorSelected.getAttribute('title') || 
                                             colorSelected.getAttribute('data-color') ||
                                             colorSelected.textContent?.trim();
              }
            }
            
            // Capture selections initially
            setTimeout(captureSelections, 1000);
            
            // Monitor for size/color changes
            const observer = new MutationObserver(captureSelections);
            observer.observe(document.body, {
              attributes: true,
              subtree: true,
              attributeFilter: ['class']
            });
            
            console.log('Dolphin: Shein page customized successfully');
            return 'success';
          } catch (error) {
            console.error('Dolphin: Error customizing Shein page:', error);
            return 'error: ' + error.toString();
          }
        })();
      ''';
      
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      print('Shein page customization result: $result');
    } catch (e) {
      print('Error customizing Shein page: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 1,
          leadingWidth: 110,
          leading: Row(
            children: [
              // WebView Back Button
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: _canGoBack ? Colors.black : AppColors.gray,
                  size: 20,
                ),
                tooltip: 'Back',
                onPressed: _canGoBack
                    ? () async {
                        await _controller.goBack();
                        _updateNavigationState();
                      }
                    : null,
              ),
              // WebView Forward Button
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: _canGoForward ? Colors.black : AppColors.gray,
                  size: 20,
                ),
                tooltip: 'Forward',
                onPressed: _canGoForward
                    ? () async {
                        await _controller.goForward();
                        _updateNavigationState();
                      }
                    : null,
              ),
            ],
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            // Home button - always go back to previous screen
            IconButton(
              icon: const Icon(Icons.home, color: AppColors.primary),
              tooltip: 'Back to Home',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              tooltip: 'Refresh',
              onPressed: () => _controller.reload(),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.primary),
              tooltip: 'More options',
              onSelected: (value) async {
                switch (value) {
                  case 'open_external':
                    // Open in external browser
                    final currentUrl = await _controller.currentUrl();
                    if (currentUrl != null) {
                      // You can add url_launcher here if needed
                    }
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'open_external',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_browser, size: 20),
                        SizedBox(width: 12),
                        Text('Open in Browser'),
                      ],
                    ),
                  ),
                ];
              },
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
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.lightGray,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isFetchingData ? null : _addToOrder,
          backgroundColor: _isFetchingData ? AppColors.gray : AppColors.primary,
          icon: _isFetchingData
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.add_shopping_cart, color: AppColors.white),
          label: Text(
            _isFetchingData ? 'Fetching...' : 'Add to Order',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}


