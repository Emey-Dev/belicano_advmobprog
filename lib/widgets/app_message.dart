import 'package:flutter/material.dart';

class AppMessage {
  const AppMessage._();

  static void success(BuildContext context, String message) =>
      _show(context, message, icon: Icons.check_circle_outline, isError: false);

  static void error(BuildContext context, String message) =>
      _show(context, message, icon: Icons.error_outline, isError: true);

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required bool isError,
  }) {
    final colors = Theme.of(context).colorScheme;
    final background = isError ? colors.errorContainer : colors.primaryContainer;
    final foreground = isError ? colors.onErrorContainer : colors.onPrimaryContainer;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          elevation: 3,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: TextStyle(color: foreground))),
            ],
          ),
        ),
      );
  }
}
