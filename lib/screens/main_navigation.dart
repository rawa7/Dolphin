import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import 'home_screen.dart';
import 'store_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store),
            label: l10n.store,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.language),
            label: l10n.websites,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag),
            label: l10n.myOrders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.account,
          ),
        ],
      ),
    );
  }
}

