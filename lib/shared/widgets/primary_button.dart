import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final IconData? icon;
  final Future<void> Function()? onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                debugPrint('🔥 PrimaryButton tapped');
                if (onPressed != null) {
                  await onPressed!();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5A52),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else ...[
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}