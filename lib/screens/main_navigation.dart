import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../utils/auth_helper.dart';
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

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> get _screens => [
    HomeScreen(onTabChange: _changeTab),
    const StoreScreen(),
    const WebsiteScreen(),
    const MyOrdersScreen(),
    const AccountScreen(),
  ];

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
    
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 3
          ? null // Hide floating button on My Orders screen
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
          currentIndex: _currentIndex > 2 ? _currentIndex : _currentIndex,
          onTap: (index) async {
            // If New Order (index 2) is tapped, open as a new screen
            if (index == 2) {
              _openAddOrder();
              // Don't change the current index, keep it on whatever tab was selected
            } else if (index == 3 || index == 4) {
              // My Orders (index 3) and Account (index 4) require authentication
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
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.gray,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: [
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
          ],
        ),
      ),
    );
  }
}

