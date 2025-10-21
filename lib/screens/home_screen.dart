import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/banner_model.dart';
import '../models/website_model.dart';
import '../constants/app_colors.dart';
import '../generated/app_localizations.dart';
import '../utils/auth_helper.dart';
import 'add_order_screen.dart';
import 'webview_screen.dart';
import 'website_screen.dart';
import 'notifications_screen.dart';
import '../models/notification_model.dart';

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
  int _unreadNotificationCount = 0;
  final PageController _bannerController = PageController();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadBanners();
    _loadWebsites();
    _loadNotificationCount();
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

  Future<void> _loadNotificationCount() async {
    final user = await StorageService.getUser();
    if (user != null) {
      final result = await ApiService.getNotifications(customerId: user.id);
      if (result['success'] && mounted) {
        final notificationData = result['data'] as NotificationData;
        setState(() {
          _unreadNotificationCount = notificationData.unreadCount;
        });
      }
    }
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoadingBanners = true;
    });

    try {
      final user = await StorageService.getUser();
      // Use customer id if available, otherwise use '0' for guests
      final customerId = user?.id.toString() ?? '0';
      final result = await ApiService.getBanners(customerId);
      
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBanners = false;
        });
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
    // Check authentication first
    final isAuthenticated = await AuthHelper.requireAuth(context);
    if (!isAuthenticated) return;
    
    // Reload user data if logged in
    await _loadUser();
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddOrderScreen(),
        ),
      );
    }
  }

  void _navigateToMyOrders() async {
    // Check authentication first
    final isAuthenticated = await AuthHelper.requireAuth(context);
    if (!isAuthenticated) return;
    
    // Reload user data if logged in
    await _loadUser();
    
    // Tab index 3 is My Orders
    if (widget.onTabChange != null) {
      widget.onTabChange!(3);
    }
  }

  void _navigateToWebsites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebsiteScreen(),
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
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo and Dolphin Shipping Text
                    Row(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 35,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.sailing,
                              size: 35,
                              color: AppColors.primary,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Dolphin Shipping',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    // Notification Icon
                    IconButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                        // Reload notification count when returning
                        if (result == true || result == null) {
                          _loadNotificationCount();
                        }
                        // Handle navigation to specific tab
                        if (result is Map && result['action'] == 'navigate' && widget.onTabChange != null) {
                          widget.onTabChange!(result['tab'] as int);
                        }
                      },
                      icon: Stack(
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          // Notification badge
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  _unreadNotificationCount > 99 
                                      ? '99+' 
                                      : _unreadNotificationCount.toString(),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
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

            // Banner Carousel (moved to top)
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
                                  final banner = _banners[index];
                                  return GestureDetector(
                                    onTap: () {
                                      if (banner.link.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => WebViewScreen(
                                              url: banner.link,
                                              title: 'Banner',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          banner.image,
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

            // Quick Action Buttons - 3 in a row (moved below banner)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.add_shopping_cart,
                        label: l10n.newOrder,
                        color: const Color(0xFFFFE5F0),
                        iconColor: const Color(0xFFE91E63),
                        onTap: _navigateToAddOrder,
                        isGradient: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.receipt_long,
                        label: l10n.myOrders,
                        color: const Color(0xFFFFF4E5),
                        iconColor: const Color(0xFFFF9800),
                        onTap: _navigateToMyOrders,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.language,
                        label: l10n.websites,
                        color: const Color(0xFFE5F4FF),
                        iconColor: const Color(0xFF2196F3),
                        onTap: _navigateToWebsites,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Website Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  l10n.website,
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
    bool isGradient = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isGradient
              ? const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isGradient ? null : color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGradient ? const Color(0xFF9C1B5E) : iconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isGradient ? Colors.white : iconColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
                color: AppColors.primary.withOpacity(0.1),
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
                  color: AppColors.primary,
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
