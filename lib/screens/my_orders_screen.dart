import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/order_model.dart';
import '../models/delivery_status_model.dart';
import '../models/user_model.dart';
import '../constants/app_colors.dart';
import '../generated/app_localizations.dart';
import 'order_detail_screen.dart';
import 'add_order_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  List<OrderStatus> _statuses = [];
  AccountInfo? _accountInfo;
  bool _isLoading = true;
  String? _selectedStatusId;
  int? _customerId;
  DeliveryStatus? _deliveryStatus;
  bool _isUpdatingDelivery = false;
  User? _user; // Track current user for account type checks

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadDeliveryStatus();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    final user = await StorageService.getUser();
    if (user == null) {
      setState(() {
        _isLoading = false;
        _user = null;
      });
      return;
    }

    _customerId = user.id;
    _user = user; // Store user for account type checks

    final result = await ApiService.getOrders(user.id);

    if (result['success']) {
      setState(() {
        _allOrders = result['orders'] as List<Order>;
        _statuses = result['statuses'] as List<OrderStatus>;
        _accountInfo = result['account_info'] as AccountInfo;
        // Show all orders by default (no filter on initial load)
        _filteredOrders = _allOrders;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterOrders(String? statusId) {
    setState(() {
      _selectedStatusId = statusId;
      if (statusId == null) {
        // For "All Orders", show all orders (no filtering)
        _filteredOrders = _allOrders;
      } else {
        _filteredOrders = _allOrders.where((order) => order.status == statusId).toList();
      }
    });
  }

  Future<void> _loadDeliveryStatus() async {
    try {
      final user = await StorageService.getUser();
      if (user != null) {
        final result = await ApiService.getDeliveryStatus(customerId: user.id);
        
        if (result['success'] && mounted) {
          setState(() {
            _deliveryStatus = result['data'] as DeliveryStatus;
          });
        }
      }
    } catch (e) {
      print('Error loading delivery status: $e');
    }
  }

  Future<void> _updateDeliveryStatus(bool enabled) async {
    if (_isUpdatingDelivery) return;

    setState(() {
      _isUpdatingDelivery = true;
    });

    try {
      final user = await StorageService.getUser();
      if (user != null) {
        final result = await ApiService.updateDeliveryStatus(
          customerId: user.id,
          deliveryStatus: enabled ? 1 : 0,
        );

        if (mounted) {
          setState(() {
            _isUpdatingDelivery = false;
          });

          if (result['success']) {
            // Reload delivery status to get updated data
            await _loadDeliveryStatus();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(enabled ? 'Delivery requested successfully!' : 'Delivery request cancelled'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Failed to update delivery status'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingDelivery = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  OrderStatus? get _selectedStatus {
    if (_selectedStatusId == null) return null;
    try {
      return _statuses.firstWhere((status) => status.id == _selectedStatusId);
    } catch (e) {
      return null;
    }
  }

  // Calculate total for "All Orders" excluding rejected (6), canceled (14), -2, and -3
  double _calculateAllOrdersTotal() {
    double total = 0.0;
    for (var order in _allOrders) {
      // Exclude rejected (6), canceled (14), -2, and -3
      if (order.status != '6' && order.status != '14' && order.status != '-2' && order.status != '-3') {
        final price = double.tryParse(order.totalPrice) ?? 0.0;
        total += price;
      }
    }
    return total;
  }

  Color _getStatusColor(String status) {
    // Map statuses to colors
    switch (status) {
      case '1': // Created
      case '7': // Created recently
        return Colors.blue;
      case '2': // Processing
      case '16': // Purchased
        return Colors.orange;
      case '3': // Approved
      case '19': // Checked
        return Colors.lightGreen;
      case '4': // In Transit
      case '17': // Out-for-delivery
        return Colors.purple;
      case '-2': // Complete
      case '-1': // delivered to erbil
      case '18': // Store
        return Colors.green;
      case '6': // Rejected
        return Colors.red;
      case '14': // Canceled
        return Colors.grey;
      case '13': // Pending
        return Colors.amber;
      case '-3': // Refunded
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Row(
                children: [
                  Text(
                    l10n.myOrders,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  // Hide "Add Order" button for bronze accounts and guests
                  if (_user != null && _user!.isBronzeAccount != true)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddOrderScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(l10n.newOrder),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Status Tabs
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatusTabWithoutCount(null, l10n.allOrders),
                const SizedBox(width: 8),
                ..._statuses.where((status) => status.count > 0).map((status) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildStatusTab(status.id, status.name, status.count),
                  )
                ),
              ],
            ),
          ),

          // Summary Box (only when a specific status is selected, NOT for "All Orders" or "Complete")
          if (_selectedStatus != null && _selectedStatusId != '-2')
            _buildSummaryBox(),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noOrdersFound,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabWithoutCount(String? statusId, String label) {
    final isSelected = _selectedStatusId == statusId;
    return GestureDetector(
      onTap: () => _filterOrders(statusId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2B4A6F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab(String? statusId, String label, int count) {
    final isSelected = _selectedStatusId == statusId;
    return GestureDetector(
      onTap: () => _filterOrders(statusId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2B4A6F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox() {
    final l10n = AppLocalizations.of(context)!;
    
    // If "All Orders" is selected (no specific status)
    final isAllOrders = _selectedStatusId == null;
    final statusName = isAllOrders ? 'All Orders' : _selectedStatus!.name;
    final total = isAllOrders ? _calculateAllOrdersTotal() : _selectedStatus!.total;
    final count = isAllOrders 
        ? _allOrders.where((order) => order.status != '6' && order.status != '14' && order.status != '-2' && order.status != '-3').length
        : _selectedStatus!.count;
    
    final formattedTotal = NumberFormat('#,##0.00').format(total);
    
    // Check if we're viewing "delivered to erbil" status (-1)
    final isDeliveredToErbil = _selectedStatusId == '-1';
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count items',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        Text(
                          '\$$formattedTotal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Delivery Request Button (only for "delivered to erbil" status)
        if (isDeliveredToErbil && _deliveryStatus != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: (_deliveryStatus?.deliveryEnabled ?? false)
                    ? [
                        const Color(0xFF4CAF50),
                        const Color(0xFF66BB6A),
                      ]
                    : [
                        const Color(0xFF5B7FE8),
                        const Color(0xFF7B9FFF),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ((_deliveryStatus?.deliveryEnabled ?? false)
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF5B7FE8))
                      .withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.deliveryRequest,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _deliveryStatus?.deliveryText ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Show button or message based on delivery status
                if (_deliveryStatus?.deliveryEnabled ?? false)
                  // Message when delivery is already requested
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                      child: Text(
                        '${l10n.youRequestedDelivery}\n${l10n.youWillGetItASAP}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                        ),
                      ],
                    ),
                  )
                else
                  // Button when delivery not requested
                  SizedBox(
                    width: double.infinity,
                    child: _isUpdatingDelivery
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              _updateDeliveryStatus(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF5B7FE8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_outline, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.requestDelivery,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(order.status);
    final price = double.tryParse(order.totalPrice) ?? 0.0;
    // All prices are in USD
    final priceDisplay = '\$${price.toStringAsFixed(2)}';
    
    final canManageOrder = order.status == '2' || order.status == '13';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            GestureDetector(
              onTap: () => _showFullImage(context, order.imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  order.imageUrl,
                  width: 110,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 110,
                      height: 140,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Order Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID and DETAILS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.serialNumber,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ': ${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailScreen(
                                order: order,
                                customerId: _customerId ?? 0,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadOrders();
                          }
                        },
                        child: Text(
                          l10n.viewDetails.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // QTY
                  Row(
                    children: [
                      Text(
                        l10n.qty,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ': ${order.qty}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Size
                  Row(
                    children: [
                      Text(
                        l10n.size,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ': ${order.size.isNotEmpty ? order.size : l10n.none}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Status badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          order.statusName.trim().toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Show "Processing order" text if status is 2
                      if (order.status == '2')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Text(
                            l10n.processingOrder,
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Price (moved to bottom, bold and bigger)
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.price,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          priceDisplay,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Accept/Reject buttons (only for manageable orders)
                  if (canManageOrder) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () => _showRejectConfirmation(order),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(
                                l10n.reject,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () => _showAcceptConfirmation(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(
                                l10n.approve,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAcceptConfirmation(Order order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.confirmApprove),
        content: Text('${l10n.approve} ${l10n.order} #${order.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(l10n.approve),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.acceptOrder(
      customerId: _customerId!,
      orderId: int.parse(order.id),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        _loadOrders();
      }
    }
  }

  Future<void> _showRejectConfirmation(Order order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.confirmReject),
        content: Text('${l10n.reject} ${l10n.order} #${order.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.reject),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.rejectOrder(
      customerId: _customerId!,
      orderId: int.parse(order.id),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.orange : Colors.red,
        ),
      );

      if (result['success']) {
        _loadOrders();
      }
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Full size image with pinch-to-zoom
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Image not available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
