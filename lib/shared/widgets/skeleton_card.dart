import 'package:flutter/material.dart';

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white12 : Colors.black12;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: double.infinity, color: baseColor),
                const SizedBox(height: 10),
                Container(height: 12, width: 120, color: baseColor),
                const SizedBox(height: 10),
                Container(height: 12, width: 180, color: baseColor),
                const SizedBox(height: 14),
                Container(height: 12, width: double.infinity, color: baseColor),
                const SizedBox(height: 8),
                Container(height: 12, width: 220, color: baseColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}