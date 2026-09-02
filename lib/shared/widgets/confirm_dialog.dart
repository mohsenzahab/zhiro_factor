import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Reusable confirmation dialog for delete actions.
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const ConfirmDialog({
    super.key,
    this.title = AppStrings.deleteConfirmTitle,
    this.message = AppStrings.deleteConfirmMessage,
    this.confirmLabel = AppStrings.delete,
    this.confirmColor = AppColors.error,
  });

  /// Shows the dialog and returns true if confirmed.
  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
    String? confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title ?? AppStrings.deleteConfirmTitle,
        message: message ?? AppStrings.deleteConfirmMessage,
        confirmLabel: confirmLabel ?? AppStrings.delete,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
