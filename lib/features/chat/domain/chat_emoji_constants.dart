/// Chat emoji constants — aligned with DuoFrontend `chatConstants.ts`.
abstract final class ChatEmojiConstants {
  static const voiceMessageLabel = '🎤 Voice message';

  /// `QUICK_REACTIONS` in Next.js.
  static const quickReactions = ['❤️', '😂', '😮', '😢', '😡', '👍'];

  /// `EMOJI_LIST` in Next.js — primary composer picker (4×4 grid).
  static const composerPicker = [
    '❤️',
    '🙌',
    '🔥',
    '😂',
    '😮',
    '😢',
    '😡',
    '👍',
    '✨',
    '🙏',
    '💯',
    '🎉',
    '🌹',
    '🍷',
    '💖',
    '🥰',
  ];

  static const recentStorageKey = 'chat_recent_emojis';
  static const maxRecent = 24;

  static const categories = <String, List<String>>{
    'Recent': [],
    'Smileys': [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
      '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
      '😘', '😗', '😚', '😙', '🥲', '😋', '😛', '😜',
      '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐',
      '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬',
      '😮', '😯', '😲', '😳', '🥺', '😢', '😭', '😤',
      '😠', '😡', '🤬', '😈', '👿', '💀', '☠️', '🤡',
    ],
    'Gestures': [
      '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️',
      '🤟', '🤘', '👌', '🤌', '🤏', '👈', '👉', '👆',
      '👇', '☝️', '👋', '🤚', '🖐️', '✋', '🖖', '👏',
      '🙌', '🤲', '🤝', '🙏', '✍️', '💪', '🦾', '🦿',
    ],
    'Hearts': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
      '💘', '💝', '💟', '♥️', '🌹', '🥀', '💐', '🌸',
    ],
    'Celebration': [
      '🔥', '✨', '⭐', '🌟', '💫', '💯', '🎉', '🎊',
      '🎈', '🎁', '🏆', '🥇', '🎯', '🎪', '🎭', '🎨',
      '🍷', '🥂', '🍾', '🍻', '🥤', '🧋', '☕', '🍰',
    ],
  };

  static List<String> get allEmojis {
    final seen = <String>{};
    final out = <String>[];
    for (final emoji in composerPicker) {
      if (seen.add(emoji)) out.add(emoji);
    }
    for (final list in categories.values) {
      for (final emoji in list) {
        if (seen.add(emoji)) out.add(emoji);
      }
    }
    return out;
  }
}
