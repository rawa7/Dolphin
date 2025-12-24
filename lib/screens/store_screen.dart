import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/shop_item_model.dart';
import '../models/shop_banner_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/auth_helper.dart';
import '../constants/app_colors.dart';
import '../generated/app_localizations.dart';
import 'product_detail_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<ShopItem> _allItems = [];
  List<ShopItem> _filteredItems = [];
  List<Brand> _brands = [];
  List<String> _categories = [];
  List<ShopBanner> _shopBanners = [];
  String? _selectedBrandId;
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isLoadingBanners = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  User? _user; // Track current user for bronze account check

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadShopItems();
    _loadShopBanners();
  }
  
  Future<void> _loadUser() async {
    final user = await StorageService.getUser();
    setState(() {
      _user = user;
    });
  }

  Future<void> _loadShopBanners() async {
    setState(() {
      _isLoadingBanners = true;
    });

    try {
      // Only load banners for logged-in non-bronze users
      final user = await StorageService.getUser();
      if (user != null && user.isBronzeAccount != true) {
        final result = await ApiService.getShopBanners();
        
        if (result['success'] && result['data'] != null) {
          setState(() {
            _shopBanners = result['data'] as List<ShopBanner>;
            _isLoadingBanners = false;
          });
        } else {
          setState(() {
            _isLoadingBanners = false;
          });
        }
      } else {
        setState(() {
          _isLoadingBanners = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingBanners = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadShopItems(),
      _loadShopBanners(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }
  
  // Helper function to fix malformed image URLs
  String _fixImageUrl(String url) {
    // Fix URLs with ".." in them (e.g., "http://domain.com../uploads/")
    return url.replaceAll('../', '/').replaceAll('../', '/');
  }

  Future<void> _loadShopItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await StorageService.getUser();
      // Allow guests to view store, pass null as customerId for guests
      final result = await ApiService.getShopItems(customerId: user?.id);

      if (result['success']) {
        final items = result['data'] as List<ShopItem>;
        
        // Extract unique brands
        final Map<String, Brand> brandMap = {};
        for (var item in items) {
          if (!brandMap.containsKey(item.brandId)) {
            brandMap[item.brandId] = Brand(
              brandId: item.brandId,
              brandName: item.brandName,
              brandImageUrl: item.brandImageUrl,
            );
          }
        }
        
        // Extract unique categories
        final Set<String> categorySet = {};
        for (var item in items) {
          if (item.itemCategory.isNotEmpty) {
            categorySet.add(item.itemCategory);
          }
        }

        setState(() {
          _allItems = items;
          _filteredItems = items;
          _brands = brandMap.values.toList();
          _categories = categorySet.toList()..sort();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load products';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _filterByBrand(String? brandId) {
    setState(() {
      _selectedBrandId = brandId;
      _applyFilters();
    });
  }
  
  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }
  
  void _applyFilters() {
    List<ShopItem> filtered = _allItems;
    
    // Apply brand filter
    if (_selectedBrandId != null) {
      filtered = filtered.where((item) => item.brandId == _selectedBrandId).toList();
      }
    
    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered.where((item) => item.itemCategory == _selectedCategory).toList();
  }

    // Apply search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((item) =>
                item.itemName.toLowerCase().contains(query) ||
                item.itemCategory.toLowerCase().contains(query) ||
          item.itemDescription.toLowerCase().contains(query)).toList();
    }
    
    setState(() {
      _filteredItems = filtered;
      });
    }

  void _applySearch() {
    _applyFilters();
  }

  Future<void> _navigateToProductDetail(ShopItem item) async {
    // Check authentication first - user needs to login to view product details and add to cart
    final isAuthenticated = await AuthHelper.requireAuth(context);
    if (!isAuthenticated) return;
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(item: item),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadShopItems,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          slivers: [
            // Store Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Text(
                    l10n.store,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),

            // Shop Banners - Only for non-bronze accounts (Silver, Gold, Platinum, Diamond, etc.)
            if (_shopBanners.isNotEmpty && _user != null && _user!.isBronzeAccount != true)
              SliverToBoxAdapter(
                child: Container(
                  height: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: PageView.builder(
                      controller: _bannerController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBannerIndex = index;
                        });
                      },
                      itemCount: _shopBanners.length,
                      itemBuilder: (context, index) {
                        final banner = _shopBanners[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to product detail if product_id is valid
                            // For now, we'll just show the banner
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Banner Image
                              Image.network(
                                banner.bannerImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported, size: 48),
                                  );
                                },
                              ),
                              // Gradient Overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                              // Banner Info
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      banner.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      banner.description,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Page Indicator
                              if (_shopBanners.length > 1)
                                Positioned(
                                  bottom: 8,
                                  right: 16,
                                  child: Row(
                                    children: List.generate(
                                      _shopBanners.length,
                                      (dotIndex) => Container(
                                        margin: const EdgeInsets.only(left: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentBannerIndex == dotIndex
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // Brand Filters - Hide for bronze accounts and guests
            if (_brands.isNotEmpty && _user != null && _user!.isBronzeAccount != true)
            SliverToBoxAdapter(
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                      // All Brands filter
                    _buildBrandFilter(
                      isSelected: _selectedBrandId == null,
                        brandName: 'All',
                        child: const Icon(Icons.apps, color: AppColors.primary),
                      onTap: () => _filterByBrand(null),
                      ),
                      // Individual brand filters
                    ..._brands.map((brand) => _buildBrandFilter(
                          isSelected: _selectedBrandId == brand.brandId,
                          brandName: brand.brandName,
                          imageUrl: brand.brandImageUrl,
                          onTap: () => _filterByBrand(brand.brandId),
                        )),
                  ],
                ),
              ),
            ),

            // Category Filters - Hide for bronze accounts and guests
            if (_categories.isNotEmpty && _user != null && _user!.isBronzeAccount != true)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // All Categories chip
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All'),
                            selected: _selectedCategory == null,
                            onSelected: (selected) => _filterByCategory(null),
                            backgroundColor: Colors.grey[100],
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _selectedCategory == null ? AppColors.primary : Colors.black87,
                              fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                            ),
                            checkmarkColor: AppColors.primary,
                          ),
                        ),
                        // Individual category chips
                        ..._categories.map((category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: _selectedCategory == category,
                                onSelected: (selected) => _filterByCategory(selected ? category : null),
                                backgroundColor: Colors.grey[100],
                                selectedColor: AppColors.primary.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: _selectedCategory == category ? AppColors.primary : Colors.black87,
                                  fontWeight: _selectedCategory == category ? FontWeight.bold : FontWeight.normal,
                                ),
                                checkmarkColor: AppColors.primary,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),

            // Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _applySearch(),
                        decoration: InputDecoration(
                          hintText: l10n.searchProducts,
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                ),
              ),
            ),

            // Product Grid
            _filteredItems.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noProductsFound,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _filteredItems[index];
                          return _buildProductCard(item);
                        },
                        childCount: _filteredItems.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandFilter({
    required bool isSelected,
    required String brandName,
    String? imageUrl,
    Widget? child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: child ??
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      _fixImageUrl(imageUrl!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.store, color: Colors.grey),
                        );
                      },
                    ),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              brandName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _downloadImage(String imageUrl) async {
    try {
      final fixedUrl = _fixImageUrl(imageUrl);
      final response = await http.get(
        Uri.parse(fixedUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final fileName = 'shop_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }

  Future<void> _orderItem(ShopItem item) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Get user info
    final user = await StorageService.getUser();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseLogin),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
    // Download image
    final imageFile = await _downloadImage(item.imagePath);
    
      if (imageFile == null) {
    // Close loading
        if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to download product image'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

      // Place order directly
      print('🛒 Ordering item: ${item.itemName}, Price: ${item.price}');
      final result = await ApiService.addOrder(
        customerId: user.id,
        link: 'Product: ${item.itemName}',
        size: item.itemDescription.isNotEmpty ? item.itemDescription : 'Standard',
        qty: 1,
        imageFile: imageFile,
        country: 'Iraq',
        price: item.price > 0 ? item.price : null, // Only send price if > 0
        currencyId: item.price > 0 ? 1 : null, // Currency ID 1 for USD
        note: 'Dolphin Store Item',
      );

      // Close loading
      if (mounted) Navigator.pop(context);

    if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to place order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
        ),
      );
      }
    }
  }

  Widget _buildProductCard(ShopItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image - Clickable
          GestureDetector(
            onTap: () => _navigateToProductDetail(item),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        _fixImageUrl(item.imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  // "NEW" badge if needed
                  if (item.itemId == '19') // Example condition
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name - Clickable
                    GestureDetector(
                      onTap: () => _navigateToProductDetail(item),
                      child: Text(
                        item.itemName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  // Price - Clickable
                  GestureDetector(
                    onTap: () => _navigateToProductDetail(item),
                    child: Row(
                      children: [
                        Text(
                          '\$${NumberFormat('#,##0.00').format(item.price)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _orderItem(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Order',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
