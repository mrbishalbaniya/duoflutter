/// Identifiers for independently filterable settings sections.
enum SettingsSectionId {
  account,
  appearance,
  notifications,
  privacy,
  security,
  storage,
  language,
  help,
  about,
  danger,
}

class SettingsSearchEntry {
  const SettingsSearchEntry({
    required this.sectionId,
    required this.keywords,
  });

  final SettingsSectionId sectionId;
  final List<String> keywords;
}

/// Registry used by the settings search bar to show/hide sections.
abstract final class SettingsSearchRegistry {
  static const entries = <SettingsSearchEntry>[
    SettingsSearchEntry(
      sectionId: SettingsSectionId.account,
      keywords: [
        'account',
        'profile',
        'email',
        'phone',
        'username',
        'password',
        'wallet',
        'verify',
        'verification',
        'premium',
        'edit',
      ],
    ),
    SettingsSearchEntry(
      sectionId: SettingsSectionId.appearance,
      keywords: ['appearance', 'theme', 'dark', 'light', 'system', 'display', 'font'],
    ),
    SettingsSearchEntry(
      sectionId: SettingsSectionId.notifications,
      keywords: ['notifications', 'push', 'messages', 'matches', 'likes', 'alerts'],
    ),
    SettingsSearchEntry(
      sectionId: SettingsSectionId.privacy,
      keywords: [
        'privacy',
        'visibility',
        'online',
        'location',
        'map',
        'discovery',
        'blocked',
        'screenshot',
      ],
    ),
    SettingsSearchEntry(
      sectionId: SettingsSectionId.security,
      keywords: ['security', 'password', 'two-factor', '2fa', 'biometric', 'sessions', 'devices'],
    ),
    SettingsSearchEntry(
      sectionId: SettingsSectionId.storage,
      keywords: ['storage', 'cache', 'media', 'download', 'clear'],
    ),
    SettingsSearchEntry(
      sectionId: SettingsSectionId.language,
      keywords: ['language', 'region', 'locale'],
    ),
    SettingsSearchEntry(
      sectionId: SettingsSectionId.help,
      keywords: ['help', 'support', 'faq', 'bug', 'report', 'contact'],
    ),
    SettingsSearchEntry(
      sectionId: SettingsSectionId.about,
      keywords: ['about', 'version', 'privacy policy', 'terms', 'licenses', 'update', 'ota'],
    ),
    SettingsSearchEntry(
      sectionId: SettingsSectionId.danger,
      keywords: ['logout', 'log out', 'delete', 'account', 'danger'],
    ),
  ];

  static Set<SettingsSectionId> matchingSections(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return SettingsSectionId.values.toSet();
    }
    final matches = <SettingsSectionId>{};
    for (final entry in entries) {
      for (final keyword in entry.keywords) {
        if (keyword.contains(normalized) || normalized.contains(keyword)) {
          matches.add(entry.sectionId);
          break;
        }
      }
    }
    return matches;
  }
}
