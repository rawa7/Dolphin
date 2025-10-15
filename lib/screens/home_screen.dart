import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/banner_model.dart';
import '../models/website_model.dart';
import '../constants/app_colors.dart';
import '../generated/app_localizations.dart';
import 'add_order_screen.dart';
import 'webview_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  
  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  List<BannerItem> _banners = [];
  List<Website> _websites = [];
  bool _isLoadingBanners = true;
  bool _isLoadingWebsites = true;
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadBanners();
    _loadWebsites();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await StorageService.getUser();
    setState(() {
      _user = user;
    });
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoadingBanners = true;
    });

    final user = await StorageService.getUser();
    if (user != null) {
      final result = await ApiService.getBanners(user.id.toString());
      
      if (result['success'] == true && mounted) {
        final bannersData = result['banners'] as List;
        setState(() {
          _banners = bannersData.map((json) => BannerItem.fromJson(json)).toList();
          _isLoadingBanners = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingBanners = false;
          });
        }
      }
    }
  }

  Future<void> _loadWebsites() async {
    setState(() {
      _isLoadingWebsites = true;
    });

    final result = await ApiService.getWebsites();
    
    if (result['success'] == true && mounted) {
      setState(() {
        _websites = result['websites'] as List<Website>;
        _isLoadingWebsites = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoadingWebsites = false;
        });
      }
    }
  }

  void _navigateToAddOrder() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddOrderScreen(),
      ),
    );
  }

  void _navigateToMyOrders() {
    // Tab index 3 is My Orders
    if (widget.onTabChange != null) {
      widget.onTabChange!(3);
    }
  }

  void _navigateToWebsites() {
    // Tab index 2 is Websites
    if (widget.onTabChange != null) {
      widget.onTabChange!(2);
    }
  }

  void _showHelp() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.helpAndSupport),
        content: Text(l10n.helpMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with Logo
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Image.network(
                      'https://dolphinshippingiq.com/uploads/2649.jpg',
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          l10n.goldenprizma,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9C1B5E),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Welcome Text
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _user != null ? l10n.helloUser(_user!.name ?? "User") : '${l10n.hello}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Quick Action Buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickActionButton(
                      icon: Icons.shopping_bag_outlined,
                      label: l10n.newOrder,
                      color: const Color(0xFFFFE5F0),
                      iconColor: const Color(0xFF9C1B5E),
                      onTap: _navigateToAddOrder,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.description_outlined,
                      label: l10n.myOrders,
                      color: const Color(0xFFFFF4E5),
                      iconColor: const Color(0xFFFF9800),
                      onTap: _navigateToMyOrders,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.language,
                      label: l10n.websites,
                      color: const Color(0xFFE5F4FF),
                      iconColor: const Color(0xFF2196F3),
                      onTap: _navigateToWebsites,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.help_outline,
                      label: l10n.help,
                      color: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF4CAF50),
                      onTap: _showHelp,
                    ),
                  ],
                ),
              ),
            ),

            // Banner Carousel
            SliverToBoxAdapter(
              child: _isLoadingBanners
                  ? const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _banners.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            SizedBox(
                              height: 180,
                              child: PageView.builder(
                                controller: _bannerController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentBannerIndex = index;
                                  });
                                },
                                itemCount: _banners.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _banners[index].image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: AppColors.lightGray,
                                            child: const Center(
                                              child: Icon(Icons.image_not_supported),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Page indicator
                            if (_banners.length > 1)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _banners.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: _currentBannerIndex == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _currentBannerIndex == index
                                          ? const Color(0xFF9C1B5E)
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
            ),

            // Hot Deals Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  l10n.hotDeals,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Websites List by Country
            _isLoadingWebsites
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : _websites.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(l10n.noWebsitesAvailable),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final groupedWebsites = _groupWebsitesByCountry();
                            final countries = groupedWebsites.keys.toList();
                            final country = countries[index];
                            final websites = groupedWebsites[country]!;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Country Header
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      country,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF9C1B5E),
                                      ),
                                    ),
                                  ),
                                  // Websites Grid
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.0,
                                    ),
                                    itemCount: websites.length,
                                    itemBuilder: (context, websiteIndex) {
                                      final website = websites[websiteIndex];
                                      return _buildWebsiteCard(website);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: _groupWebsitesByCountry().length,
                        ),
                      ),

            // Bottom Padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteCard(Website website) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              url: website.link,
              title: website.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Website Image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.network(
                  website.imageUrl ?? '',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.language, size: 40, color: AppColors.gray);
                  },
                ),
              ),
            ),
            // Website Name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF9C1B5E).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                website.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9C1B5E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Website>> _groupWebsitesByCountry() {
    final Map<String, List<Website>> grouped = {};
    for (var website in _websites) {
      if (!grouped.containsKey(website.country)) {
        grouped[website.country] = [];
      }
      grouped[website.country]!.add(website);
    }
    return grouped;
  }
}
