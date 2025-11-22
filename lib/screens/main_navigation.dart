import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../utils/auth_helper.dart';
import '../services/storage_service.dart';
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
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Dynamic screens list based on account type
  List<Widget> get _screens {
    final bool isBronze = _user?.isBronzeAccount == true;
    
    if (isBronze) {
      // Bronze users: Home, Store, My Orders, Account (no Websites, no Add Order)
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
  int get _myOrdersIndex => _user?.isBronzeAccount == true ? 2 : 3;

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
    
    return Scaffold(
      body: _screens[_currentIndex],
      // Hide floating action button for bronze users and on My Orders screen
      floatingActionButton: (isBronze || _currentIndex == _myOrdersIndex)
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
            if (isBronze) {
              // Bronze users: Simple navigation (Home, Store, My Orders, Account)
              if (index == 2 || index == 3) {
                // My Orders and Account require authentication
                final isAuthenticated = await AuthHelper.requireAuth(context);
                if (!isAuthenticated) return;
              }
              setState(() {
                _currentIndex = index;
              });
            } else {
              // Regular users: Full navigation
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
          items: _buildNavItems(l10n, isBronze),
        ),
      ),
    );
  }
  
  // Build navigation items dynamically based on account type
  List<BottomNavigationBarItem> _buildNavItems(AppLocalizations l10n, bool isBronze) {
    if (isBronze) {
      // Bronze users: Home, Store, My Orders, Account (no Websites, no Add Order)
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

