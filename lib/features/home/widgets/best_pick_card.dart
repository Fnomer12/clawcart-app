import 'package:flutter/material.dart';

class BestPickCard extends StatelessWidget {
  final Map<String, dynamic> bestProduct;
  final Color panelBg;
  final Color titleColor;
  final Color subColor;

  const BestPickCard({
    super.key,
    required this.bestProduct,
    required this.panelBg,
    required this.titleColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF5A52),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A52).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Color(0xFFFF5A52),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bestProduct['name']?.toString() ?? '-',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bestProduct['reason']?.toString() ?? '',
            style: TextStyle(
              color: subColor,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}