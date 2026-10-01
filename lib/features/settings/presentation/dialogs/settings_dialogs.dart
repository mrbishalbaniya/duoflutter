import 'package:flutter/material.dart';

Future<bool?> showLogoutDialog(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: CircleAvatar(
        radius: 28,
        backgroundColor: scheme.error.withValues(alpha: 0.15),
        child: Icon(Icons.logout_rounded, color: scheme.error, size: 28),
      ),
      title: const Text('Log out of Duo?', textAlign: TextAlign.center),
      content: const Text(
        "You'll be signed out on this device. Your matches and chats stay saved, "
        'and you can sign back in anytime.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
              child: const Text('Yes, log out'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              autofocus: true,
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, stay logged in'),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<bool?> showClearCacheDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear cache?'),
      content: const Text(
        'This clears locally cached chat threads and downloaded images. Your account data is not affected.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear cache'),
        ),
      ],
    ),
  );
}
