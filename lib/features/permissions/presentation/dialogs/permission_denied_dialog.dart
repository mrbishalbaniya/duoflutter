import 'package:flutter/material.dart';

import '../../models/permission_models.dart';

Future<void> showPermissionDeniedDialog(
  BuildContext context, {
  required DuoPermissionDefinition definition,
  required DuoPermissionStatus status,
  required VoidCallback onOpenSettings,
}) {
  final permanentlyDenied = status == DuoPermissionStatus.permanentlyDenied;

  return showDialog<void>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        icon: Icon(definition.icon, color: definition.accent, size: 32),
        title: Text(permanentlyDenied ? '${definition.title} blocked' : '${definition.title} not allowed'),
        content: Text(
          permanentlyDenied
              ? 'Duo needs ${definition.title.toLowerCase()} access for core features. '
                  'Open Settings to enable it manually.'
              : 'You can continue without ${definition.title.toLowerCase()}, '
                  'but some features may not work until you allow access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          if (permanentlyDenied)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOpenSettings();
              },
              child: const Text('Open Settings'),
            ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: scheme.surfaceContainerHigh,
      );
    },
  );
}
