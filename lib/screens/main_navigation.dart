import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../utils/auth_helper.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import 'store_screen.dart';
import 'add_order_screen.dart';
import 'website_screen.dart';
import 'my_orders_screen.dart';
import 'account_screen.dart';
import '../constants/app_colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await StorageService.getUser();
    
    // If user is logged in, refresh their data from server to get latest usertype
    if (user != null) {
      try {
        print('🔄 Refreshing user data from server...');
        final result = await ApiService.getProfile(customerId: user.id);
        
        if (result['success']) {
          final profileData = result['data'];
          final profile = profileData.profile;
          
          // Create updated user with latest usertype from server
          final updatedUser = User(
            id: user.id,
            name: profile.name,
            phone: profile.phone,
            email: profile.email,
            address: profile.address,
            isActive: int.tryParse(profile.isActive) ?? 1,
            createdAt: user.createdAt,
            usertype: profile.usertype, // Fresh usertype from server!
          );
          
          // Save updated user to storage
          await StorageService.saveUser(updatedUser);
          print('✅ User data refreshed. Usertype: ${updatedUser.usertype}, Bronze: ${updatedUser.isBronzeAccount}');
          
          setState(() {
            _user = updatedUser;
            _isLoading = false;
          });
        } else {
          // If API fails, use cached user data
          print('⚠️ Failed to refresh user data, using cached data');
          setState(() {
            _user = user;
            _isLoading = false;
          });
        }
      } catch (e) {
        // If error occurs, use cached user data
        print('⚠️ Error refreshing user data: $e, using cached data');
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } else {
      // No user logged in
      setState(() {
        _user = null;
        _isLoading = false;
      });
    }
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Dynamic screens list based on account type
  List<Widget> get _screens {
    final bool isBronze = _user?.isBronzeAccount == true;
    final bool isGuest = _user == null;
    
    // Bronze or Guest users: Home, Store, My Orders, Account (no Websites, no Add Order)
    if (isBronze || isGuest) {
      return [
        HomeScreen(onTabChange: _changeTab),
        const StoreScreen(),
        const MyOrdersScreen(),
        const AccountScreen(),
      ];
    } else {
      // Regular users: All screens
      return [
        HomeScreen(onTabChange: _changeTab),
        const StoreScreen(),
        const WebsiteScreen(),
        const MyOrdersScreen(),
        const AccountScreen(),
      ];
    }
  }
  
  // Get the correct My Orders index based on account type
  // Bronze or Guest: 4 tabs (index 2), Regular: 5 tabs (index 3)
  int get _myOrdersIndex => (_user?.isBronzeAccount == true || _user == null) ? 2 : 3;

  void _openAddOrder() async {
    // Check authentication first
    final isAuthenticated = await AuthHelper.requireAuth(context);
    if (!isAuthenticated) return;
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddOrderScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Show loading while checking user account type
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final bool isBronze = _user?.isBronzeAccount == true;
    final bool isGuest = _user == null; // Not logged in
    
    return Scaffold(
      body: _screens[_currentIndex],
      // Hide floating action button for:
      // - Bronze users
      // - Guest users (not logged in)
      // - On My Orders screen
      floatingActionButton: (isBronze || isGuest || _currentIndex == _myOrdersIndex)
          ? null
          : FloatingActionButton(
              onPressed: _openAddOrder,
              backgroundColor: AppColors.primary,
              elevation: 6,
              child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) async {
            // Bronze or Guest users: Simple 4-tab navigation (Home, Store, My Orders, Account)
            if (isBronze || isGuest) {
              if (index == 2 || index == 3) {
                // My Orders and Account require authentication
                final isAuthenticated = await AuthHelper.requireAuth(context);
                if (!isAuthenticated) return;
              }
              setState(() {
                _currentIndex = index;
              });
            } else {
              // Regular users: Full 5-tab navigation with New Order
              if (index == 2) {
                // New Order - open as modal screen
                _openAddOrder();
              } else if (index == 3 || index == 4) {
                // My Orders and Account require authentication
                final isAuthenticated = await AuthHelper.requireAuth(context);
                if (!isAuthenticated) return;
                setState(() {
                  _currentIndex = index;
                });
              } else {
                setState(() {
                  _currentIndex = index;
                });
              }
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.gray,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: _buildNavItems(l10n, isBronze, isGuest),
        ),
      ),
    );
  }
  
  // Build navigation items dynamically based on account type
  List<BottomNavigationBarItem> _buildNavItems(AppLocalizations l10n, bool isBronze, bool isGuest) {
    // Bronze or Guest users: Home, Store, My Orders, Account (no New Order tab)
    if (isBronze || isGuest) {
      // Bronze/Guest users: Home, Store, My Orders, Account (no Websites, no Add Order)
      return [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home, size: 26),
          label: l10n.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.store, size: 26),
          label: l10n.store,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_bag, size: 26),
          label: l10n.myOrders,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person, size: 26),
          label: l10n.account,
        ),
      ];
    } else {
      // Regular users: Full navigation
      return [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home, size: 26),
          label: l10n.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.store, size: 26),
          label: l10n.store,
        ),
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: Colors.white,
              size: 28,
            ),
          ),
          label: l10n.newOrder,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_bag, size: 26),
          label: l10n.myOrders,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person, size: 26),
          label: l10n.account,
        ),
      ];
    }
  }
}

