import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/website_model.dart';
import '../constants/app_colors.dart';
import '../utils/auth_helper.dart';
import 'webview_screen.dart';
import 'add_order_screen.dart';

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  List<Website> _allWebsites = [];
  List<Website> _filteredWebsites = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWebsites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWebsites() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getWebsites();

    if (result['success']) {
      setState(() {
        _allWebsites = result['websites'];
        _filteredWebsites = _allWebsites;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  void _filterWebsites(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredWebsites = _allWebsites;
      } else {
        _filteredWebsites = _allWebsites.where((website) {
          return website.name.toLowerCase().contains(_searchQuery) ||
              website.country.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  Map<String, List<Website>> _groupWebsitesByCountry(List<Website> websites) {
    final Map<String, List<Website>> grouped = {};
    for (var website in websites) {
      if (!grouped.containsKey(website.country)) {
        grouped[website.country] = [];
      }
      grouped[website.country]!.add(website);
    }
    return grouped;
  }

  Future<void> _openWebsite(Website website) async {
    if (website.link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website link not available')),
      );
      return;
    }

    // Check if it's a Shein link - if so, call API directly
    if (_isSheinUrl(website.link)) {
      await _handleSheinLink(website.link);
    } else {
      // For non-Shein sites, open webview as normal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: website.link,
            title: website.name,
          ),
        ),
      );
    }
  }

  bool _isSheinUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('shein.com') || 
           lowerUrl.contains('sheinlink://') || 
           lowerUrl.startsWith('shein://');
  }

  Future<void> _handleSheinLink(String url) async {
    // Check authentication first
    final isAuthenticated = await AuthHelper.requireAuth(context);
    if (!isAuthenticated) {
      return; // User cancelled or not logged in
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Call Shein API directly
      final apiResult = await ApiService.getSheinProduct(url);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (apiResult['success'] == true && apiResult['data'] != null) {
          final extractedData = apiResult['data'] as Map<String, dynamic>;
          
          // Navigate directly to Add Order screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddOrderScreen(
                initialData: extractedData,
                initialUrl: url,
              ),
            ),
          );
        } else {
          // API failed, show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(apiResult['message'] ?? 'Failed to fetch product data'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedWebsites = _groupWebsitesByCountry(_filteredWebsites);
    final sortedCountries = groupedWebsites.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/logo.png',
          height: 40,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'Dolphin',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.shadow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterWebsites,
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: AppColors.textHint),
                        prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.shadow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: AppColors.gray),
                    onPressed: () {
                      // Handle filter
                    },
                  ),
                ),
              ],
            ),
          ),

          // Websites list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _filteredWebsites.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.language,
                              size: 80,
                              color: AppColors.lightGray,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No websites found',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadWebsites,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: sortedCountries.length,
                          itemBuilder: (context, index) {
                            final country = sortedCountries[index];
                            final websites = groupedWebsites[country]!;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Country header
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          country.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Websites grid
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 1.4,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                      itemCount: websites.length,
                                      itemBuilder: (context, websiteIndex) {
                                        final website = websites[websiteIndex];
                                        return _buildWebsiteCard(website);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteCard(Website website) {
    return GestureDetector(
      onTap: () => _openWebsite(website),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (website.imageUrl != null && website.imageUrl!.isNotEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.network(
                    website.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackLogo(website.name);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildFallbackLogo(website.name),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(String name) {
    return Center(
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
