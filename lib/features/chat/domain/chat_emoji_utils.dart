import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import 'chat_emoji_constants.dart';

/// Persists recent composer emojis (Hive settings box).
class ChatEmojiRecentStore {
  ChatEmojiRecentStore(this._read, this._write);

  final List<String> Function(String key) _read;
  final Future<void> Function(String key, List<String> value) _write;

  factory ChatEmojiRecentStore.fromRef(WidgetRef ref) {
    final storage = ref.read(localStorageProvider);
    return ChatEmojiRecentStore(
      (key) {
        final raw = storage.settings.get(key);
        if (raw is! List) return const [];
        return raw.whereType<String>().toList();
      },
      (key, value) async {
        await storage.settings.put(key, value);
      },
    );
  }

  List<String> load() =>
      _read(ChatEmojiConstants.recentStorageKey);

  Future<List<String>> record(String emoji) async {
    final trimmed = emoji.trim();
    if (trimmed.isEmpty) return load();

    final recent = List<String>.from(load())..remove(trimmed);
    recent.insert(0, trimmed);
    final capped = recent.take(ChatEmojiConstants.maxRecent).toList();
    await _write(ChatEmojiConstants.recentStorageKey, capped);
    return capped;
  }
}

/// Inserts [emoji] at the current cursor, preserving selection semantics.
void insertEmojiAtCursor(TextEditingController controller, String emoji) {
  final value = controller.value;
  final text = value.text;
  final selection = value.selection;

  var start = selection.start;
  var end = selection.end;
  if (start < 0 || end < 0) {
    start = text.length;
    end = text.length;
  }

  final newText = text.replaceRange(start, end, emoji);
  final offset = start + emoji.length;
  controller.value = value.copyWith(
    text: newText,
    selection: TextSelection.collapsed(offset: offset),
    composing: TextRange.empty,
  );
}

/// Whether the composer has sendable content (matches Next.js `length > 0`).
bool composerHasSendableText(String text) => text.isNotEmpty;
