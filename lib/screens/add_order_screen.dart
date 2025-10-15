import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/web_scraper_service.dart';
import '../services/webview_scraper_service.dart';
import '../models/currency_model.dart';
import '../generated/app_localizations.dart';

class AddOrderScreen extends StatefulWidget {
  final String? initialUrl;
  final Map<String, dynamic>? initialData;
  final File? prefilledImage;
  final String? prefilledPrice;
  final String? prefilledNote;
  final String? prefilledCountry;
  final String? prefilledLink;
  final String? prefilledSize;

  const AddOrderScreen({
    super.key,
    this.initialUrl,
    this.initialData,
    this.prefilledImage,
    this.prefilledPrice,
    this.prefilledNote,
    this.prefilledCountry,
    this.prefilledLink,
    this.prefilledSize,
  });

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  final _colorController = TextEditingController();
  final _noteController = TextEditingController();
  final _priceController = TextEditingController();
  
  String? _selectedCountry;
  String? _selectedSize;
  int _quantity = 1;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isFetchingDetails = false;
  Map<String, dynamic>? _fetchedProductData;
  String? _extractedPrice;
  String? _extractedCurrency;
  
  // Currency state
  List<Currency> _currencies = [];
  Currency? _selectedCurrency;
  bool _isLoadingCurrencies = false;
  
  // For detecting paste operations
  String _previousUrl = '';
  bool _isApplyingInitialData = false;

  final List<String> _countries = [
    'Iraq',
    'Shein',
    'Turkey',
    'UAE',
    'USA',
    'UK',
    'Germany',
    'France',
    'China',
  ];

  final List<String> _sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    'Free Size',
  ];

  @override
  void initState() {
    super.initState();
    _noteController.addListener(() {
      setState(() {}); // Update character count dynamically
    });
    _fetchCurrencies();
    
    // Apply prefilled data from store if provided
    if (widget.prefilledImage != null) {
      _isApplyingInitialData = true;
      _selectedImage = widget.prefilledImage;
      
      if (widget.prefilledPrice != null) {
        _extractedPrice = widget.prefilledPrice;
        _priceController.text = '\$ ${widget.prefilledPrice}';
        
        // Set USD as currency (id: 1)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            if (_currencies.isNotEmpty) {
              try {
                _selectedCurrency = _currencies.firstWhere(
                  (c) => c.currencyCode == 'USD',
                );
              } catch (e) {
                // If USD not found, use first currency
                _selectedCurrency = _currencies.first;
              }
            }
          });
        });
      }
      
      if (widget.prefilledSize != null) {
        _selectedSize = widget.prefilledSize!;
      }
      
      if (widget.prefilledNote != null) {
        _noteController.text = widget.prefilledNote!;
      }
      
      if (widget.prefilledCountry != null) {
        _selectedCountry = widget.prefilledCountry!;
      }
      
      if (widget.prefilledLink != null) {
        _linkController.text = widget.prefilledLink!;
        _previousUrl = widget.prefilledLink!;
      }
      
      _isApplyingInitialData = false;
    }
    // Apply initial data if provided (before adding listener)
    else if (widget.initialUrl != null) {
      _linkController.text = widget.initialUrl!;
      _previousUrl = widget.initialUrl!;
      
      // If no initialData is provided, trigger auto-fetch after a short delay
      // This happens when coming from WebView "Add to Order" button
      if (widget.initialData == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Auto-fetch product details
            _fetchProductDetails();
          }
        });
      } else {
        _isApplyingInitialData = true;
      }
    }
    
    if (widget.initialData != null) {
      _applyInitialData(widget.initialData!);
    }
    
    // Add listener after initial data is set to prevent auto-fetch loop
    _linkController.addListener(_onUrlChanged);
  }
  
  void _applyInitialData(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      setState(() {
        _fetchedProductData = data;
        
        // Auto-detect and set country from URL
        if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
          _selectedCountry = _detectCountryFromUrl(widget.initialUrl!);
        }
        
        // Auto-fill price if found
        if (data['price'] != null && data['price'].toString().isNotEmpty) {
          _extractedPrice = data['price'].toString();
          _extractedCurrency = data['currency']?.toString() ?? '';
          _priceController.text = '$_extractedCurrency $_extractedPrice';
          
          // Auto-select currency based on detected currency code
          if (_extractedCurrency != null && _extractedCurrency!.isNotEmpty && _currencies.isNotEmpty) {
            final currencyCode = _extractedCurrency!.toUpperCase();
            Currency? matchedCurrency;
            
            try {
              matchedCurrency = _currencies.firstWhere(
                (c) => c.currencyCode == currencyCode,
              );
            } catch (e) {
              try {
                matchedCurrency = _currencies.firstWhere(
                  (c) => c.currencySign == _extractedCurrency,
                );
              } catch (e) {
                // Keep default currency if no match found
              }
            }
            
            if (matchedCurrency != null) {
              _selectedCurrency = matchedCurrency;
            }
          }
        }
        
        // Auto-fill color if found
        if (data['color'] != null && data['color'].toString().isNotEmpty) {
          _colorController.text = data['color'];
        }
        
        // Auto-select size if found
        if (data['size'] != null) {
          final size = data['size'].toString().toUpperCase();
          if (_sizes.contains(size)) {
            _selectedSize = size;
          }
        }
        
        // Set image if provided
        if (data['imageFile'] != null && data['imageFile'] is File) {
          _selectedImage = data['imageFile'];
        }
      });
    });
  }
  
  // Auto-fetch when URL changes (detects paste operations)
  void _onUrlChanged() {
    final currentUrl = _linkController.text;
    
    // Skip auto-fetch if we're applying initial data from WebView
    if (_isApplyingInitialData) {
      _previousUrl = currentUrl;
      _isApplyingInitialData = false; // Reset the flag
      return;
    }
    
    // Clear previous fetched data if URL is empty
    if (currentUrl.isEmpty) {
      setState(() {
        _fetchedProductData = null;
        _extractedPrice = null;
        _extractedCurrency = null;
        _priceController.clear();
        _selectedImage = null;
        _colorController.clear();
      });
      _previousUrl = '';
      return;
    }
    
    // Detect paste operation: significant text change (more than 10 characters added at once)
    final lengthDiff = currentUrl.length - _previousUrl.length;
    if (lengthDiff > 10 && currentUrl.contains('http')) {
      // This looks like a paste operation, trigger auto-fetch
      _onUrlPasted();
    }
    
    _previousUrl = currentUrl;
  }
  
  // Trigger auto-fetch after paste
  Future<void> _onUrlPasted() async {
    // Wait a moment for the text to be set
    await Future.delayed(const Duration(milliseconds: 100));
    if (_linkController.text.isNotEmpty) {
      _fetchProductDetails();
    }
  }
  
  Future<void> _fetchCurrencies() async {
    setState(() {
      _isLoadingCurrencies = true;
    });

    final result = await ApiService.getCurrencies();

    if (mounted) {
      setState(() {
        _isLoadingCurrencies = false;
      });

      if (result['success']) {
        setState(() {
          _currencies = result['currencies'] as List<Currency>;
          // Set USD as default (id: 1)
          _selectedCurrency = _currencies.firstWhere(
            (c) => c.id == 1,
            orElse: () => _currencies.isNotEmpty ? _currencies.first : Currency(
              id: 1,
              currencyName: 'Dolar',
              currencySign: '\$',
              currencyCode: 'USD',
              currencyConvert: 1.0,
            ),
          );
        });
      } else {
        _showMessage('Failed to load currencies: ${result['message']}', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _linkController.removeListener(_onUrlChanged);
    _linkController.dispose();
    _colorController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _detectCountryFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    if (lowerUrl.contains('shein.com')) {
      return 'Shein';
    } else if (lowerUrl.contains('trendyol.com')) {
      return 'Turkey';
    } else if (lowerUrl.contains('amazon.ae') || lowerUrl.contains('.ae')) {
      return 'UAE';
    } else if (lowerUrl.contains('amazon.com') || lowerUrl.contains('.us')) {
      return 'USA';
    } else if (lowerUrl.contains('amazon.co.uk') || lowerUrl.contains('.uk')) {
      return 'UK';
    } else if (lowerUrl.contains('amazon.de') || lowerUrl.contains('.de')) {
      return 'Germany';
    } else if (lowerUrl.contains('amazon.fr') || lowerUrl.contains('.fr')) {
      return 'France';
    } else if (lowerUrl.contains('.cn') || lowerUrl.contains('alibaba') || lowerUrl.contains('aliexpress')) {
      return 'China';
    } else if (lowerUrl.contains('zara.com')) {
      // Try to detect from URL path
      if (lowerUrl.contains('/ae/')) return 'UAE';
      if (lowerUrl.contains('/us/')) return 'USA';
      if (lowerUrl.contains('/uk/')) return 'UK';
      if (lowerUrl.contains('/de/')) return 'Germany';
      if (lowerUrl.contains('/fr/')) return 'France';
      if (lowerUrl.contains('/tr/')) return 'Turkey';
    } else if (lowerUrl.contains('hm.com') || lowerUrl.contains('h&m')) {
      if (lowerUrl.contains('/ae/')) return 'UAE';
      if (lowerUrl.contains('/us/')) return 'USA';
      if (lowerUrl.contains('/uk/')) return 'UK';
      if (lowerUrl.contains('/de/')) return 'Germany';
    }
    
    // Default - let user select
    return 'Turkey'; // Default fallback
  }

  Future<void> _fetchProductDetails() async {
    if (_linkController.text.trim().isEmpty) {
      _showMessage('Please enter a product URL first', isError: true);
      return;
    }

    setState(() {
      _isFetchingDetails = true;
    });

    // First try regular HTML scraping
    var result = await WebScraperService.fetchProductDetails(_linkController.text.trim());

    // If regular scraping fails, try WebView scraping for JavaScript-heavy sites
    if (!result['success'] || (result['data'] != null && result['data']['images'].isEmpty)) {
      final url = _linkController.text.trim();
      final lowerUrl = url.toLowerCase();
      
      // Use WebView for known JavaScript-heavy sites
      if (lowerUrl.contains('shein.com') || 
          lowerUrl.contains('zara.com') || 
          lowerUrl.contains('amazon.') ||
          lowerUrl.contains('hm.com') ||
          !result['success']) {
        
        result = await WebViewScraperService.fetchProductDetailsWithWebView(
          context, 
          _linkController.text.trim()
        );
      }
    }

    setState(() {
      _isFetchingDetails = false;
    });

    if (result['success']) {
      // Cast to proper type
      final data = Map<String, dynamic>.from(result['data'] as Map);
      _fetchedProductData = data;

      // Auto-detect and set country from URL
      if (_linkController.text.isNotEmpty) {
        final detectedCountry = _detectCountryFromUrl(_linkController.text);
        setState(() {
          _selectedCountry = detectedCountry;
        });
      }

      // Auto-fill price if found
      if (data['price'] != null && data['price'].toString().isNotEmpty) {
        setState(() {
          _extractedPrice = data['price'].toString();
          _extractedCurrency = data['currency']?.toString() ?? '';
          _priceController.text = '$_extractedCurrency $_extractedPrice';
        });
        
        // Auto-select currency based on detected currency code
        if (_extractedCurrency != null && _extractedCurrency!.isNotEmpty && _currencies.isNotEmpty) {
          final currencyCode = _extractedCurrency!.toUpperCase();
          Currency? matchedCurrency;
          
          // Try to find exact match by currency code
          try {
            matchedCurrency = _currencies.firstWhere(
              (c) => c.currencyCode == currencyCode,
            );
          } catch (e) {
            // If not found by code, try by sign
            try {
              matchedCurrency = _currencies.firstWhere(
                (c) => c.currencySign == _extractedCurrency,
              );
            } catch (e) {
              // Keep default currency if no match found
            }
          }
          
          if (matchedCurrency != null) {
            setState(() {
              _selectedCurrency = matchedCurrency;
            });
          }
        }
      }

      // Auto-fill color if found
      if (data['color'] != null && data['color'].toString().isNotEmpty) {
        _colorController.text = data['color'];
      }

      // Auto-select size if found and matches our sizes
      if (data['size'] != null) {
        final size = data['size'].toString().toUpperCase();
        if (_sizes.contains(size)) {
          setState(() {
            _selectedSize = size;
          });
        }
      }

      // Set image if already downloaded via WebView
      if (data['imageFile'] != null && data['imageFile'] is File) {
        setState(() {
          _selectedImage = data['imageFile'];
        });
      } 
      // Otherwise download and set the first image
      else if (data['images'] != null && (data['images'] as List).isNotEmpty) {
        final imageUrl = (data['images'] as List).first;
        await _downloadAndSetImage(imageUrl);
      }
      // If still no image, automatically take screenshot
      else if (_selectedImage == null) {
        _showMessage('No product image found. Please take a screenshot or upload manually.', isError: true);
      }

      // Auto-fill description with fetched data (now only title and description)
      if (data['title'] != null || data['description'] != null) {
        String description = '';
        if (data['title'] != null) {
          description += '${data['title']}\n';
        }
        if (data['description'] != null && data['description'].toString().length < 300) {
          description += '\n${data['description']}';
        }
        _noteController.text = description.trim();
      }

      _showMessage('Product details fetched successfully!', isError: false);
    } else {
      // Show error message
      final message = result['message'] ?? 'Could not fetch product details';
      _showMessage(message, isError: true);
    }
  }

  Future<void> _downloadAndSetImage(String imageUrl) async {
    try {
      final response = await WebScraperService.downloadImage(imageUrl);
      if (response != null) {
        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        
        setState(() {
          _selectedImage = file;
        });
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(l10n.takePhoto),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1920,
                    maxHeight: 1920,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.chooseFromGallery),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1920,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Required fields validation
    if (_selectedSize == null) {
      _showMessage('Please select a size', isError: true);
      return;
    }

    if (_selectedImage == null) {
      _showMessage('Please upload a product image', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get customer ID from storage
    final user = await StorageService.getUser();
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('User not found. Please login again.', isError: true);
      return;
    }

    // Parse price to double (optional)
    double? price;
    if (_extractedPrice != null && _extractedPrice!.isNotEmpty) {
      try {
        price = double.parse(_extractedPrice!);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showMessage('Invalid price format', isError: true);
        return;
      }
    }

    final result = await ApiService.addOrder(
      customerId: user.id,
      link: _linkController.text,
      size: _selectedSize!,
      qty: _quantity,
      imageFile: _selectedImage!,
      country: _selectedCountry, // Optional
      price: price, // Optional
      currencyId: _selectedCurrency?.id, // Optional
      color: _colorController.text.isNotEmpty ? _colorController.text : null,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      _showMessage(result['message'], isError: false);
      // Navigate back after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      });
    } else {
      String errorMessage = result['message'];
      if (result['errors'] != null && result['errors'].isNotEmpty) {
        errorMessage += '\n' + result['errors'].join('\n');
      }
      _showMessage(errorMessage, isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.placeOrder,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language, color: Colors.grey[800]),
            onPressed: () {
              // Handle language change
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Link field with paste/clear buttons
            Text(
              l10n.link,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink[700]!),
              ),
              child: TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  hintText: l10n.pasteProductLink,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Clear button
                      if (_linkController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _linkController.clear();
                            });
                          },
                          tooltip: l10n.close,
                        ),
                      // Paste button
                      IconButton(
                        icon: Icon(Icons.content_paste, color: Colors.pink[700]),
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data != null && data.text != null) {
                            setState(() {
                              _linkController.text = data.text!;
                            });
                            _onUrlPasted();
                          }
                        },
                        tooltip: 'Paste',
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Link is required';
                  }
                  return null;
                },
              ),
            ),
            
            // Loading indicator when fetching
            if (_isFetchingDetails)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.pink[700],
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Fetching product details...',
                      style: TextStyle(
                        color: Colors.pink[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Price Display (Read-only, Optional) - Hidden but working in background
            Visibility(
              visible: false,
              maintainState: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detected Price (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextFormField(
                      controller: _priceController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Price will be detected automatically',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: _extractedPrice != null
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.info_outline, color: Colors.grey),
                ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _extractedPrice != null ? Colors.green[700] : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // const SizedBox(height: 20), // Removed since field is hidden

            // Country dropdown (Optional)
            const Text(
              'Country (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                hint: const Text('Select country'),
                items: _countries.map((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCountry = newValue;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Currency dropdown (Optional) - Hidden but working in background
            Visibility(
              visible: false,
              maintainState: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Currency (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonFormField<Currency>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      hint: _isLoadingCurrencies
                          ? const Text('Loading currencies...')
                          : const Text('Select currency'),
                      items: _currencies.map((Currency currency) {
                        return DropdownMenuItem<Currency>(
                          value: currency,
                          child: Text(currency.fullDisplayName),
                        );
                      }).toList(),
                      onChanged: _isLoadingCurrencies
                          ? null
                          : (Currency? newValue) {
                              setState(() {
                                _selectedCurrency = newValue;
                              });
                            },
                    ),
                  ),
                  if (_selectedCurrency != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16),
                      child: Text(
                        'Convert rate: ${_selectedCurrency!.currencyConvert} ${_selectedCurrency!.currencyCode} = 1 USD',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Size, Quantity, Color and Image row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Size, Quantity, Color
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Size dropdown
                      const Text(
                        'Size',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedSize,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          hint: const Text('Select'),
                          items: _sizes.map((String size) {
                            return DropdownMenuItem<String>(
                              value: size,
                              child: Text(size),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSize = newValue;
                            });
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quantity
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              },
                            ),
                            Text(
                              _quantity.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Color field
                      const Text(
                        'Color (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextFormField(
                          controller: _colorController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Red',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right side - Image upload
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Image',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 280,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                          ),
                          child: _selectedImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Upload image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedImage = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _noteController,
                    maxLines: 5,
                    maxLength: 500,
                    buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) {
                      return null; // Hide default counter
                    },
                    decoration: const InputDecoration(
                      hintText: 'Add any additional notes here...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_noteController.text.length}/500',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Place order button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Place order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.pink[700],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

