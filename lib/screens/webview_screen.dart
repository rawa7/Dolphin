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
              
              // Get SHEIN images - use detail_image for main product photo
              const images = [];
              if (detail.detail_image) {
                images.push(detail.detail_image);
              }
              if (detail.goods_img) {
                images.push(detail.goods_img);
              }
              if (detail.goods_imgs && Array.isArray(detail.goods_imgs)) {
                detail.goods_imgs.forEach(img => {
                  if (img.origin_image && !images.includes(img.origin_image)) {
                    images.push(img.origin_image);
                  }
                });
              }
              data.images = images;
              
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
            
            // Try to get images - prioritize high-quality product images
            const images = [];
            
            // 1. Meta og:image (usually high quality)
            const ogImage = document.querySelector('meta[property="og:image"]')?.content;
            if (ogImage) images.push(ogImage);
            
            // 2. Twitter image (backup)
            const twitterImage = document.querySelector('meta[name="twitter:image"]')?.content;
            if (twitterImage && !images.includes(twitterImage)) images.push(twitterImage);
            
            // 3. Specific product image selectors
            const productImageSelectors = [
              'img[itemprop="image"]',
              'img[class*="productImage"]',
              'img[class*="product-image"]',
              'img[class*="ProductImage"]',
              'img[data-zoom-image]',
              '.product-main-image img',
              '.product-image-container img:first-child',
              '[class*="ImageViewer"] img:first-child'
            ];
            
            for (const selector of productImageSelectors) {
              const img = document.querySelector(selector);
              if (img && img.src && !images.includes(img.src)) {
                images.push(img.src);
              }
            }
            
            data.images = images;
            
            // Try to get color
            const colorElement = document.querySelector('[class*="color"] [class*="selected"]') ||
                                document.querySelector('[data-color]');
            data.color = colorElement?.textContent?.trim() || '';
            
            // Try to get size
            const sizeElement = document.querySelector('[class*="size"] [class*="selected"]') ||
                               document.querySelector('[data-size]');
            data.size = sizeElement?.textContent?.trim() || '';
            
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
      
      // Try to download the first image if available
      File? imageFile;
      if (data['images'] != null && data['images'] is List && (data['images'] as List).isNotEmpty) {
        print('Found ${(data['images'] as List).length} images in data');
        final imageUrl = (data['images'] as List)[0].toString();
        print('Attempting to download image from: $imageUrl');
        
        try {
          // Add timeout to prevent hanging (increased to 10 seconds)
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
      } else {
        print('No images found in extracted data');
      }
      
      // If image download failed or no images found, take a screenshot
      if (imageFile == null) {
        try {
          print('Image download failed, taking screenshot...');
          imageFile = await _captureScreenshot();
          if (imageFile != null) {
            print('Screenshot captured successfully');
          }
        } catch (e) {
          print('Error capturing screenshot: $e');
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
      print('Attempting to capture screenshot...');
      
      // Use JavaScript to get the main product image from the page
      const jsCode = '''
        (function() {
          try {
            // Try multiple selectors for product images
            const selectors = [
              'meta[property="og:image"]',
              'img[class*="product"][class*="main"]',
              'img[class*="Product"][class*="Main"]',
              'img[itemprop="image"]',
              'img[data-product]',
              'img.product-image',
              '.product-images img:first-child',
              '.product__media img:first-child'
            ];
            
            for (const selector of selectors) {
              const element = document.querySelector(selector);
              if (element) {
                if (selector.includes('meta')) {
                  return element.content;
                } else {
                  return element.src || element.getAttribute('data-src') || element.getAttribute('data-original');
                }
              }
            }
            
            // Fallback: get first large image
            const allImages = Array.from(document.querySelectorAll('img'));
            const largeImage = allImages.find(img => 
              img.naturalWidth > 300 && img.naturalHeight > 300
            );
            
            if (largeImage) {
              return largeImage.src;
            }
            
            return null;
          } catch (error) {
            return null;
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      print('Screenshot JS result: $result');
      
      if (result != null && result.toString().isNotEmpty && result.toString() != 'null') {
        String imageUrl = result.toString();
        
        // Remove quotes if present
        if (imageUrl.startsWith('"') && imageUrl.endsWith('"')) {
          imageUrl = imageUrl.substring(1, imageUrl.length - 1);
        }
        
        print('Found image URL from page: $imageUrl');
        
        // Download this image
        final imageFile = await _downloadImage(imageUrl).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('Image download from page timed out');
            return null;
          },
        );
        
        if (imageFile != null) {
          print('Successfully downloaded image from page');
          return imageFile;
        }
      }
      
      print('Could not capture screenshot - no suitable image found');
      return null;
    } catch (e) {
      print('Error capturing screenshot: $e');
      return null;
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
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
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _updateNavigationState() async {
    final canGoBack = await _controller.canGoBack();
    final canGoForward = await _controller.canGoForward();
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
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

