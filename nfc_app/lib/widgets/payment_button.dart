// widgets/payment_button.dart
import 'package:flutter/material.dart';

class PaymentButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPayPressed;
  final VoidCallback onReplenishPressed;

  const PaymentButton({
    super.key,
    required this.isLoading,
    required this.onPayPressed,
    required this.onReplenishPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onPayPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2e7d32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[400],
            ),
            child: Text(
              isLoading ? 'ОПЛАТА...' : 'ОПЛАТИТЬ\n50 ₽',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onReplenishPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[400],
            ),
            child: Text(
              isLoading ? 'ПОПОЛНЕНИЕ...' : 'ПОПОЛНИТЬ\n500 ₽',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}