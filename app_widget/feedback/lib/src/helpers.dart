import 'package:app_locale/app_locale.dart';
import 'package:duskmoon_feedback/duskmoon_feedback.dart';
import 'package:flutter/material.dart';

/// Show an error snackbar with theme-compliant error color.
void showAppErrorSnackbar(BuildContext context, String message) {
  showDmSnackbar(
    context: context,
    message: Text(message),
    showCloseIcon: true,
  );
}

/// Show a success snackbar with theme-compliant styling.
void showAppSuccessSnackbar(BuildContext context, String message) {
  showDmSnackbar(
    context: context,
    message: Text(message),
  );
}

/// Show a delete confirmation dialog with error-colored confirm action.
Future<bool> showAppDeleteDialog(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  final result = await showDmDialog<bool>(
    context: context,
    title: Text(title),
    content: Text(content),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(context.l10n.cancel),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(true),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: Text(context.l10n.delete),
      ),
    ],
  );
  return result ?? false;
}
