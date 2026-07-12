import 'package:flutter/material.dart';

Future<bool?> showLogoutDialog(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to sign in again to access your account.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          child: const Text('Log out'),
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

Future<void> showSettingsComingSoonDialog(BuildContext context, {required String title}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text('$title is coming soon.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    ),
  );
}
