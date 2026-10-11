import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Tooltip wrapper with an intentional delay (~1200ms) to protect user privacy
/// and prevent accidental glance of sensitive cost, profit, and stock data.
class PrivacyTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final Duration waitDuration;
  final Duration showDuration;

  const PrivacyTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration = const Duration(milliseconds: 1200),
    this.showDuration = const Duration(seconds: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      waitDuration: waitDuration,
      showDuration: showDuration,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      textStyle: const TextStyle(
        fontSize: 12,
        color: Colors.white,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.dividerDark),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
