import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CancelDeliveryScreen extends StatefulWidget {
  final String orderId;
  final String productName;
  final String etaMinutes;
  final String destination;

  const CancelDeliveryScreen({
    super.key,
    this.orderId = 'GLO-29384-TX',
    this.productName = 'iPhone 15 Pro Max',
    this.etaMinutes = '24 MINS',
    this.destination = 'Akwa, Douala',
  });

  @override
  State<CancelDeliveryScreen> createState() => _CancelDeliveryScreenState();
}

class _CancelDeliveryScreenState extends State<CancelDeliveryScreen> {
  String? _selectedReason;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _reasons = [
    {
      'icon': Icons.access_time_outlined,
      'label': 'Delivery is taking too long',
    },
    {
      'icon': Icons.psychology_outlined,
      'label': 'Changed my mind',
    },
    {
      'icon': Icons.local_offer_outlined,
      'label': 'Found a better price elsewhere',
    },
    {
      'icon': Icons.location_off_outlined,
      'label': 'Incorrect delivery address',
    },
    {
      'icon': Icons.more_horiz,
      'label': 'Other reason',
    },
  ];

  Future<void> _confirmCancellation() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner une raison'),
          backgroundColor: AppColors.navy,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pop(context, {'cancelled': true, 'reason': _selectedReason});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Glotelho Express',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline,
                color: Colors.black87, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Titre
            const Text(
              'Cancel Delivery?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #${widget.orderId} is currently being processed. Please let us know why you\'re cancelling.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Carte commande
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Image produit placeholder
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.phone_android,
                        size: 36, color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ARRIVING IN ${widget.etaMinutes}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.productName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Text(
                              'Destination: ${widget.destination}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
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

            const SizedBox(height: 28),

            // SELECT REASON
            const Text(
              'SELECT REASON',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Liste des raisons
            ..._reasons.map((reason) {
              final label = reason['label'] as String;
              final isSelected = _selectedReason == label;
              return GestureDetector(
                onTap: () => setState(() => _selectedReason = label),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.gold
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        reason['icon'] as IconData,
                        size: 20,
                        color: isSelected
                            ? AppColors.gold
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          color: isSelected
                              ? AppColors.gold
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                            size: 12, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Alerte frais d'annulation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 13, color: Colors.red, height: 1.5),
                        children: [
                          TextSpan(
                            text: 'Cancellation Fee May Apply\n',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                            'Since the driver is already on the way, a fee of ',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.normal),
                          ),
                          TextSpan(
                            text: '1,500 FCFA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' will be charged to your account.',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Bouton Confirm Cancellation
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _confirmCancellation,
                icon: _isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 20),
                label: Text(
                  _isLoading ? 'En cours...' : 'Confirm Cancellation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Keep Order
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Keep Order',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}