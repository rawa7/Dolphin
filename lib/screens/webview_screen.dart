import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/app_colors.dart';
import '../utils/auth_helper.dart';
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
      // Extract data directly from the webview (for Shein and other sites)
      final extractedData = await _extractDataFromWebView();
      
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

      // Get current URL as fallback
      final currentUrl = await _controller.currentUrl() ?? widget.url;

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
            
            // Priority 1: Specific product image selectors (most reliable for main image)
            const mainProductImageSelectors = [
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
              'img[class*="product-image"]:first-child',
              '.gallery img:first-child',
              '[class*="product-gallery"] img:first-child'
            ];
            
            for (const selector of mainProductImageSelectors) {
              const img = document.querySelector(selector);
              if (img && img.src && !images.includes(img.src)) {
                images.push(img.src);
                break; // Found main image, stop searching
              }
            }
            
            // Priority 2: Meta og:image (usually main product image)
            const ogImage = document.querySelector('meta[property="og:image"]')?.content;
            if (ogImage && !images.includes(ogImage)) images.push(ogImage);
            
            // Priority 3: Twitter image (backup)
            const twitterImage = document.querySelector('meta[name="twitter:image"]')?.content;
            if (twitterImage && !images.includes(twitterImage)) images.push(twitterImage);
            
            // Priority 4: Additional product images (only if we found main image)
            if (images.length > 0) {
              const additionalImageSelectors = [
                'img[class*="productImage"]',
                'img[class*="product-image"]',
                'img[class*="ProductImage"]'
              ];
              
              for (const selector of additionalImageSelectors) {
                const imgs = document.querySelectorAll(selector);
                imgs.forEach(img => {
                  if (img.src && !images.includes(img.src)) {
                    images.push(img.src);
                  }
                });
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
      
      // PRIORITY 1: Take a screenshot first (most reliable for main product image)
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
      
      // PRIORITY 2: If screenshot failed, try to download from URL
      if (imageFile == null && data['images'] != null && data['images'] is List && (data['images'] as List).isNotEmpty) {
        print('Screenshot failed, attempting to download from URL...');
        final imageUrl = (data['images'] as List)[0].toString();
        print('Attempting to download image from: $imageUrl');
        
        try {
          imageFile = await _downloadImage(imageUrl).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('Image download timed out after 10 seconds');
              return null;
            },
          );
          
          if (imageFile != null) {
            print('Successfully downloaded image: ${imageFile.path}');
          } else {
            print('Image download returned null');
          }
        } catch (e) {
          print('Error downloading image: $e');
        }
      }
      
      // Add the image file to data if we have one
      if (imageFile != null) {
        data['imageFile'] = imageFile;
      }
      
      return data;
    } catch (e) {
      print('Error extracting data from WebView: $e');
      return null;
    }
  }
  
  Future<File?> _downloadImage(String imageUrl) async {
    try {
      print('Downloading image from: $imageUrl');
      
      // Add headers to mimic browser request
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
        },
      );
      
      print('Download response status: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final extension = imageUrl.contains('.png') ? 'png' : 'jpg';
        final file = File('${tempDir.path}/product_image_${DateTime.now().millisecondsSinceEpoch}.$extension');
        await file.writeAsBytes(response.bodyBytes);
        print('Image saved to: ${file.path}, size: ${response.bodyBytes.length} bytes');
        return file;
      } else {
        print('Failed to download: status ${response.statusCode}, body length: ${response.bodyBytes.length}');
      }
    } catch (e) {
      print('Failed to download image: $e');
    }
    return null;
  }
  
  Future<File?> _captureScreenshot() async {
    try {
      print('Attempting to extract main product image...');
      
      // Use JavaScript to get the best quality main product image URL
      const jsCode = '''
        (function() {
          try {
            // For SHEIN - get the highest quality image
            if (typeof window.gbProductDetail !== 'undefined' && window.gbProductDetail && window.gbProductDetail.detail) {
              const detail = window.gbProductDetail.detail;
              
              // Priority 1: goods_img (main display image)
              if (detail.goods_img) {
                return detail.goods_img;
              }
              
              // Priority 2: First origin_image from goods_imgs (highest quality)
              if (detail.goods_imgs && Array.isArray(detail.goods_imgs) && detail.goods_imgs.length > 0) {
                if (detail.goods_imgs[0].origin_image) {
                  return detail.goods_imgs[0].origin_image;
                }
              }
              
              // Priority 3: detail_image
              if (detail.detail_image) {
                return detail.detail_image;
              }
            }
            
            // For other sites - comprehensive search
            // Priority 1: Meta og:image (usually best quality)
            const ogImage = document.querySelector('meta[property="og:image"]');
            if (ogImage && ogImage.content && ogImage.content.startsWith('http')) {
              return ogImage.content;
            }
            
            // Priority 2: Main product image with data attributes (usually high quality)
            const dataImageSelectors = [
              'img[data-zoom-image]',
              'img[data-large-image]',
              'img[data-full-image]',
              'img[data-original]'
            ];
            
            for (const selector of dataImageSelectors) {
              const element = document.querySelector(selector);
              if (element) {
                const dataAttr = element.getAttribute('data-zoom-image') || 
                               element.getAttribute('data-large-image') || 
                               element.getAttribute('data-full-image') ||
                               element.getAttribute('data-original');
                if (dataAttr && dataAttr.startsWith('http')) {
                  return dataAttr;
                }
              }
            }
            
            // Priority 3: Main product image selectors
            const mainImageSelectors = [
              'img[itemprop="image"]',
              '.product-main-image img',
              '.product-image-container img',
              'img[class*="mainImage"]',
              'img[id*="mainImage"]',
              'img[class*="ProductImage"]:first-of-type',
              '[class*="ImageViewer"] img:first-of-type',
              '.gallery img:first-of-type',
              '[class*="product-gallery"] img:first-of-type'
            ];
            
            for (const selector of mainImageSelectors) {
              const element = document.querySelector(selector);
              if (element && element.src && element.src.startsWith('http')) {
                // Check if it's a reasonably sized image (not a thumbnail)
                if (element.naturalWidth >= 300 && element.naturalHeight >= 300) {
                  return element.src;
                }
              }
            }
            
            // Priority 4: Find the largest visible image on the page
            const allImages = Array.from(document.querySelectorAll('img'));
            let largestImage = null;
            let maxSize = 0;
            
            for (const img of allImages) {
              if (img.src && img.src.startsWith('http') && img.naturalWidth > 0 && img.naturalHeight > 0) {
                const size = img.naturalWidth * img.naturalHeight;
                if (size > maxSize && img.naturalWidth >= 400 && img.naturalHeight >= 400) {
                  maxSize = size;
                  largestImage = img.src;
                }
              }
            }
            
            if (largestImage) {
              return largestImage;
            }
            
            return null;
          } catch (error) {
            console.error('Error extracting image:', error);
            return null;
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      print('Image extraction JS result: $result');
      
      if (result != null && result.toString().isNotEmpty && result.toString() != 'null') {
        String imageUrl = result.toString();
        
        // Remove quotes if present
        if (imageUrl.startsWith('"') && imageUrl.endsWith('"')) {
          imageUrl = imageUrl.substring(1, imageUrl.length - 1);
        }
        
        print('Found main product image URL: $imageUrl');
        
        // Download this image with extended timeout
        final imageFile = await _downloadImage(imageUrl).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('Image download timed out after 15 seconds');
            return null;
          },
        );
        
        if (imageFile != null) {
          print('Successfully downloaded main product image');
          return imageFile;
        }
      }
      
      print('Could not extract main product image');
      return null;
    } catch (e) {
      print('Error capturing main product image: $e');
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
            setState(() {
              _isLoading = true;
            });
            _updateNavigationState();
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            // Update navigation buttons state
            _updateNavigationState();
            
            // Inject custom CSS and JS for Shein pages
            if (url.toLowerCase().contains('shein.com')) {
              await _customizeSheinPage();
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
    
    // Handle Shein app links (sheinlink://applink/goods/ID or shein://...)
    if (lowerUrl.startsWith('sheinlink://') || lowerUrl.startsWith('shein://')) {
      // Extract product ID from the URL
      final goodsIdMatch = RegExp(r'goods[/_](\d+)', caseSensitive: false).firstMatch(url);
      if (goodsIdMatch != null) {
        final productId = goodsIdMatch.group(1);
        return 'https://m.shein.com/goods-$productId.html';
      }
      
      // Also try to extract from data parameter
      final dataMatch = RegExp(r'goods_id.*?(\d{6,})', caseSensitive: false).firstMatch(url);
      if (dataMatch != null) {
        final productId = dataMatch.group(1);
        return 'https://m.shein.com/goods-$productId.html';
      }
      
      // Try to find any number that might be a product ID
      final idMatch = RegExp(r'(\d{6,})').firstMatch(url);
      if (idMatch != null) {
        final productId = idMatch.group(1);
        return 'https://m.shein.com/goods-$productId.html';
      }
    }
    
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
            WebViewWidget(controller: _controller),
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


