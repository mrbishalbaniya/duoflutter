class PasswordStrength {
  const PasswordStrength({
    required this.score,
    required this.label,
    required this.requirements,
  });

  final double score;
  final String label;
  final List<PasswordRequirement> requirements;
}

class PasswordRequirement {
  const PasswordRequirement({required this.label, required this.met});

  final String label;
  final bool met;
}

PasswordStrength evaluatePasswordStrength(String password) {
  final checks = <PasswordRequirement>[
    PasswordRequirement(label: 'At least 8 characters', met: password.length >= 8),
    PasswordRequirement(label: 'Uppercase letter', met: RegExp(r'[A-Z]').hasMatch(password)),
    PasswordRequirement(label: 'Lowercase letter', met: RegExp(r'[a-z]').hasMatch(password)),
    PasswordRequirement(label: 'Number', met: RegExp(r'[0-9]').hasMatch(password)),
    PasswordRequirement(
      label: 'Special character',
      met: RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/]').hasMatch(password),
    ),
  ];

  final metCount = checks.where((c) => c.met).length;
  final score = metCount / checks.length;

  String label;
  if (score <= 0.2) {
    label = 'Very weak';
  } else if (score <= 0.4) {
    label = 'Weak';
  } else if (score <= 0.6) {
    label = 'Fair';
  } else if (score <= 0.8) {
    label = 'Good';
  } else {
    label = 'Strong';
  }

  return PasswordStrength(score: score, label: label, requirements: checks);
}

String? validatePasswordChangeForm({
  required String currentPassword,
  required String newPassword,
  required String confirmPassword,
}) {
  if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
    return 'Please fill in all password fields.';
  }
  if (newPassword != confirmPassword) {
    return 'New passwords do not match.';
  }
  final strength = evaluatePasswordStrength(newPassword);
  if (strength.score < 0.6) {
    return 'Choose a stronger password that meets more requirements.';
  }
  return null;
}

String formatRelativeTime(DateTime? dateTime) {
  if (dateTime == null) return 'Unknown';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

String devicePlatformIcon(String platform) {
  switch (platform) {
    case 'web':
      return '💻';
    case 'ios':
      return '📱';
    case 'android':
      return '📱';
    default:
      return '🖥';
  }
}
