import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../generated/app_localizations.dart';
import 'webview_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final int customerId;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.customerId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isProcessing = false;

  Future<void> _acceptOrder() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmAccept),
        content: Text(l10n.areYouSureAccept),
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
            child: Text(l10n.accept),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    final result = await ApiService.acceptOrder(
      customerId: widget.customerId,
      orderId: int.parse(widget.order.id),
    );

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    }
  }

  Future<void> _rejectOrder() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmReject),
        content: Text(l10n.areYouSureReject),
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

    setState(() {
      _isProcessing = true;
    });

    final result = await ApiService.rejectOrder(
      customerId: widget.customerId,
      orderId: int.parse(widget.order.id),
    );

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.orange : Colors.red,
        ),
      );

      if (result['success']) {
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    }
  }

  void _openLink() {
    // Open link in WebViewScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: widget.order.link,
          title: widget.order.country.isNotEmpty 
              ? widget.order.country 
              : 'Product Page',
        ),
      ),
    );
  }

  void _reorderProduct() {
    // Navigate to WebViewScreen with the product link
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: widget.order.link,
          title: widget.order.country.isNotEmpty 
              ? widget.order.country 
              : 'Product Page',
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  // Check if order can be accepted or rejected
  bool _canManageOrder() {
    // Only allow accept/reject for status 2 (Processing) or 13 (Pending)
    return widget.order.status == '2' || widget.order.status == '13';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final price = double.tryParse(widget.order.totalPrice) ?? 0.0;
    final itemPrice = double.tryParse(widget.order.itemPrice) ?? 0.0;
    final shipping = double.tryParse(widget.order.shippingPrice) ?? 0.0;
    final internalShipping = double.tryParse(widget.order.cargo) ?? 0.0;
    final commission = double.tryParse(widget.order.commission) ?? 0.0;
    final tax = double.tryParse(widget.order.tax) ?? 0.0;
    final statusColor = _getStatusColor(widget.order.status);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.orderDetails,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Product Image
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => _showFullImage(context, widget.order.imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.order.imageUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 80),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Order Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.orderDetails,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Reorder button
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _reorderProduct,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(l10n.reorder),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C1B5E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ID
                  _buildDetailRow(l10n.serialNumber, widget.order.serial),
                  const Divider(height: 1),

                  // Status
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.status,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.order.statusName.trim(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Link
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.link,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openLink,
                            child: Text(
                              widget.order.link.length > 40
                                  ? '${widget.order.link.substring(0, 40)}...'
                                  : widget.order.link,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Brand
                  if (widget.order.country.isNotEmpty)
                    _buildDetailRow(l10n.brand, widget.order.country),
                  if (widget.order.country.isNotEmpty) const Divider(height: 1),

                  // Size
                  _buildDetailRow(l10n.size, widget.order.size.isNotEmpty ? widget.order.size : l10n.none),
                  const Divider(height: 1),

                  // Quantity
                  _buildDetailRow(l10n.quantity, widget.order.qty),
                  const Divider(height: 1),

                  // Item Price
                  _buildDetailRow(
                    l10n.itemPrice,
                    '${widget.order.currencySymbol ?? ''}${itemPrice.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 1),

                  // Shipping (always USD)
                  _buildDetailRow(l10n.shipping, '\$${shipping.toStringAsFixed(2)}'),
                  const Divider(height: 1),

                  // Internal Shipping (Cargo) (always USD)
                  _buildDetailRow(l10n.cargo, '\$${internalShipping.toStringAsFixed(2)}'),
                  const Divider(height: 1),

                  // Commission (always USD)
                  _buildDetailRow(l10n.commission, '\$${commission.toStringAsFixed(2)}'),
                  const Divider(height: 1),

                  // Tax (always USD)
                  _buildDetailRow(l10n.tax, '\$${tax.toStringAsFixed(2)}'),
                  
                  const SizedBox(height: 24),

                  // Accept/Reject Buttons
                  if (_canManageOrder())
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _rejectOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    l10n.reject,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _acceptOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    l10n.accept,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

