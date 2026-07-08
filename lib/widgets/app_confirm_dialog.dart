import 'package:flutter/material.dart';

Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = 'Anuluj',
  String confirmText = 'Usuń',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );

  return result ?? false;
}