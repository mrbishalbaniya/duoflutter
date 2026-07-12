String? validatePasswordChange({
  required String currentPassword,
  required String newPassword,
  required String confirmPassword,
}) {
  if (newPassword != confirmPassword) {
    return 'New passwords do not match.';
  }
  if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
    return 'Please fill in all password fields.';
  }
  return null;
}

String formatWalletBalance(int? balance) {
  final value = balance ?? 0;
  return 'NPR ${value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      )}';
}
