import 'package:flutter/material.dart';

Future<bool> showUnmatchDialog(BuildContext context) {
  return showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Unmatch & block?'),
          content: const Text(
            'You will lose this conversation and match. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Unmatch'),
            ),
          ],
        ),
      ).then((v) => v ?? false);
}

Future<bool> showDeleteConversationDialog(BuildContext context) {
  return showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete conversation?'),
          content: const Text('This removes the chat from your inbox.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ).then((v) => v ?? false);
}

Future<bool> showClearHistoryDialog(BuildContext context) {
  return showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Clear chat history?'),
          content: const Text(
            'All messages in this conversation will be removed for you.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        ),
      ).then((v) => v ?? false);
}

Future<String?> showNicknameDialog(
  BuildContext context, {
  required String currentName,
  String? initialNickname,
}) {
  final controller = TextEditingController(text: initialNickname ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Set nickname'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display name for $currentName',
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nickname (optional)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class ChatPrivacySettings {
  const ChatPrivacySettings({
    required this.notifyScreenshots,
    required this.secureChat,
  });

  final bool notifyScreenshots;
  final bool secureChat;
}

Future<ChatPrivacySettings?> showPrivacySettingsDialog(
  BuildContext context, {
  required bool notifyScreenshots,
  required bool secureChat,
}) {
  var notify = notifyScreenshots;
  var secure = secureChat;

  return showDialog<ChatPrivacySettings>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Chat privacy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: notify,
              onChanged: (value) => setState(() => notify = value ?? true),
              title: const Text('Notify participants when screenshots are taken'),
              subtitle: const Text(
                'When enabled, others are alerted if you capture this chat.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: secure,
              onChanged: (value) => setState(() => secure = value),
              title: const Text('Secure chat'),
              subtitle: const Text(
                'Blocks screenshots on Android while this chat is open.',
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              ChatPrivacySettings(
                notifyScreenshots: notify,
                secureChat: secure,
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<String?> showReportDialog(BuildContext context) {
  final reasons = [
    'Inappropriate messages',
    'Harassment or bullying',
    'Spam or scam',
    'Fake profile',
    'Other',
  ];
  String selected = reasons.first;
  final otherController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Report user'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v!),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons
                      .map(
                        (r) => RadioListTile<String>(
                          title: Text(r, style: const TextStyle(fontSize: 14)),
                          value: r,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
              if (selected == 'Other')
                TextField(
                  controller: otherController,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final reason = selected == 'Other'
                  ? otherController.text.trim()
                  : selected;
              if (reason.isEmpty) return;
              Navigator.pop(ctx, reason);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Report'),
          ),
        ],
      ),
    ),
  );
}
