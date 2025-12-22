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
import '../models/size_model.dart';
import '../models/currency_rate_model.dart';
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
  
  // Size state
  List<Size> _sizes = [];
  bool _isLoadingSizes = false;
  
  // Currency rates state
  List<CurrencyRate> _currencyRates = [];
  bool _isLoadingCurrencyRates = false;
  
  // For detecting paste operations
  String _previousUrl = '';
  bool _isApplyingInitialData = false;

  final List<String> _countries = [
    'Iraq',
    'Shein',
    'Turkey',
    'UAE',
    'USA',
    'Germany',
  ];

  @override
  void initState() {
    super.initState();
    _noteController.addListener(() {
      setState(() {}); // Update character count dynamically
    });
    _fetchCurrencies();
    _fetchSizes();
    _fetchCurrencyRates();
    
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

  String _extractUrlFromText(String text) {
    // Regular expression to match URLs
    final urlPattern = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    
    final match = urlPattern.firstMatch(text);
    if (match != null) {
      return match.group(0)!;
    }
    
    // If no http/https URL found, return the original text
    return text.trim();
  }

  Future<void> _fetchSizes() async {
    setState(() {
      _isLoadingSizes = true;
    });

    final result = await ApiService.getSizes();

    if (mounted) {
      setState(() {
        _isLoadingSizes = false;
      });

      if (result['success']) {
        setState(() {
          _sizes = result['sizes'] as List<Size>;
        });
      } else {
        _showMessage('Failed to load sizes: ${result['message']}', isError: true);
      }
    }
  }

  Future<void> _fetchCurrencyRates() async {
    setState(() {
      _isLoadingCurrencyRates = true;
    });

    final result = await ApiService.getCurrencyRates();

    if (mounted) {
      setState(() {
        _isLoadingCurrencyRates = false;
      });

      if (result['success']) {
        final currencyRatesData = result['data'] as CurrencyRatesData;
        setState(() {
          _currencyRates = currencyRatesData.currencies;
        });
      }
    }
  }

  String _getCurrencyCodeForCountry(String country) {
    switch (country) {
      case 'Turkey':
        return 'TRY';
      case 'UAE':
        return 'AED';
      case 'UK':
        return 'GBP';
      case 'Germany':
      case 'France':
        return 'EUR';
      case 'USA':
      case 'Iraq':
      case 'Shein':
      case 'China':
      default:
        return 'USD';
    }
  }

  CurrencyRate? _getCurrencyRateForCountry(String? country) {
    if (country == null || _currencyRates.isEmpty) return null;
    
    final currencyCode = _getCurrencyCodeForCountry(country);
    try {
      return _currencyRates.firstWhere((rate) => rate.code == currencyCode);
    } catch (e) {
      return null;
    }
  }

  Future<void> _showSizeSearchDialog() async {
    if (_sizes.isEmpty) return;

    final TextEditingController searchController = TextEditingController();
    
    final selectedSize = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        List<Size> filteredSizes = List.from(_sizes);
        bool hasSearchText = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Size', style: TextStyle(fontSize: 16)),
              contentPadding: const EdgeInsets.all(16),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    // Search field
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search size...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: hasSearchText
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  searchController.clear();
                                  setDialogState(() {
                                    filteredSizes = List.from(_sizes);
                                    hasSearchText = false;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (value) {
                        setDialogState(() {
                          hasSearchText = value.isNotEmpty;
                          if (value.isEmpty) {
                            filteredSizes = List.from(_sizes);
                          } else {
                            filteredSizes = _sizes
                                .where((size) => size.name
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Size list
                    Expanded(
                      child: filteredSizes.isEmpty
                          ? const Center(
                              child: Text(
                                'No sizes found',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredSizes.length,
                              itemBuilder: (context, index) {
                                final size = filteredSizes[index];
                                final isSelected = _selectedSize == size.name;
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  title: Text(
                                    size.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.pink[700] : Colors.black,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle, color: Colors.pink[700], size: 20)
                                      : null,
                                  onTap: () {
                                    // Unfocus text field first to avoid conflicts
                                    FocusScope.of(context).unfocus();
                                    // Small delay to ensure unfocus completes
                                    Future.delayed(const Duration(milliseconds: 50), () {
                                      if (context.mounted) {
                                        Navigator.pop(context, size.name);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                ),
              ],
            );
          },
        );
      },
    );

    searchController.dispose();
    
    // Update the selected size after dialog is closed
    if (selectedSize != null && mounted) {
      setState(() {
        _selectedSize = selectedSize;
      });
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

      // Don't auto-fill description - user requested to keep it empty
      // The description field will remain blank for user to fill manually

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
    print('🟢 SUBMIT ORDER - Starting...');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ SUBMIT ORDER - Form validation failed');
      return;
    }

    // Required fields validation
    if (_selectedSize == null) {
      print('❌ SUBMIT ORDER - Size not selected');
      _showMessage('Please select a size', isError: true);
      return;
    }

    if (_selectedImage == null) {
      print('❌ SUBMIT ORDER - Image not selected');
      _showMessage('Please upload a product image', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get customer ID from storage
    final user = await StorageService.getUser();
    if (user == null) {
      print('❌ SUBMIT ORDER - User not found');
      setState(() {
        _isLoading = false;
      });
      _showMessage('User not found. Please login again.', isError: true);
      return;
    }

    print('🟢 SUBMIT ORDER - User ID: ${user.id}');

    // Parse price to double (optional)
    double? price;
    if (_extractedPrice != null && _extractedPrice!.isNotEmpty) {
      try {
        price = double.parse(_extractedPrice!);
        print('🟢 SUBMIT ORDER - Price: $price');
      } catch (e) {
        print('❌ SUBMIT ORDER - Invalid price format: $e');
        setState(() {
          _isLoading = false;
        });
        _showMessage('Invalid price format', isError: true);
        return;
      }
    }

    print('🟢 SUBMIT ORDER - Calling API with:');
    print('   - Link: ${_linkController.text}');
    print('   - Size: $_selectedSize');
    print('   - Quantity: $_quantity');
    print('   - Country: $_selectedCountry');
    print('   - Currency ID: ${_selectedCurrency?.id}');
    print('   - Color: ${_colorController.text}');
    print('   - Note: ${_noteController.text.length} chars');
    print('   - Image: ${_selectedImage!.path}');

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

    print('🟢 SUBMIT ORDER - API Result: ${result['success']}');
    print('🟢 SUBMIT ORDER - API Message: ${result['message']}');

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      print('✅ SUBMIT ORDER - Success!');
      _showMessage(result['message'], isError: false);
      // Navigate back after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      });
    } else {
      print('❌ SUBMIT ORDER - Failed');
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
          padding: const EdgeInsets.all(12),
          children: [
            // Link field with paste/clear buttons
            Text(
              l10n.link,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink[700]!),
              ),
              child: TextFormField(
                controller: _linkController,
                onChanged: (value) {
                  // Auto-extract URL when user pastes directly into the field
                  if (value.isNotEmpty && value.contains(' ')) {
                    final extractedUrl = _extractUrlFromText(value);
                    if (extractedUrl != value) {
                      // Only update if extraction found a different URL
                      _linkController.value = TextEditingValue(
                        text: extractedUrl,
                        selection: TextSelection.collapsed(offset: extractedUrl.length),
                      );
                    }
                  }
                  setState(() {}); // Refresh to show/hide clear button
                },
                decoration: InputDecoration(
                  hintText: l10n.pasteProductLink,
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
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
                            // Extract only the URL from the text
                            final extractedUrl = _extractUrlFromText(data.text!);
                            setState(() {
                              _linkController.text = extractedUrl;
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
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.pink[700],
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fetching product details...',
                      style: TextStyle(
                        color: Colors.pink[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

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
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                        border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Select country', style: TextStyle(fontSize: 12)),
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

            // Currency conversion rate info
            if (_selectedCountry != null && _getCurrencyRateForCountry(_selectedCountry) != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  'Currency: ${_getCurrencyRateForCountry(_selectedCountry)!.name} (${_getCurrencyRateForCountry(_selectedCountry)!.symbol}) - Rate: ${_getCurrencyRateForCountry(_selectedCountry)!.conversionRate.toStringAsFixed(2)} to USD',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 12),

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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: _isLoadingCurrencies
                          ? const Text('Loading currencies...', style: TextStyle(fontSize: 12))
                          : const Text('Select currency', style: TextStyle(fontSize: 12)),
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
                      // Size dropdown (searchable)
                      const Text(
                        'Size',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _isLoadingSizes ? null : _showSizeSearchDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedSize ?? (_isLoadingSizes ? 'Loading...' : 'Select'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _selectedSize != null ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Quantity
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                                fontSize: 16,
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
                      
                      const SizedBox(height: 10),
                      
                      // Color field
                      const Text(
                        'Color (Optional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Image',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 240,
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
                                      size: 36,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
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

            const SizedBox(height: 12),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
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
                    maxLines: 3,
                    maxLength: 500,
                    buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) {
                      return null; // Hide default counter
                    },
                    decoration: const InputDecoration(
                      hintText: 'Add any additional notes here...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_noteController.text.length}/500',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Place order button
            SizedBox(
              height: 48,
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Place order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 10),

            // Cancel button
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.pink[700],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

