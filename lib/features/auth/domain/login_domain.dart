/// Validation and navigation helpers aligned with DuoFrontend `/login`.
String? validateLoginEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email is required';
  final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!emailPattern.hasMatch(email)) return 'Enter a valid email address';
  return null;
}

String? validateLoginPassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  return null;
}

/// Mirrors Next.js `safeNext` guard in `app/login/page.tsx`.
String? sanitizeNextPath(String? path) {
  if (path == null || path.isEmpty) return null;
  if (!path.startsWith('/')) return null;
  if (path.startsWith('//')) return null;
  return path;
}

String mapLoginError(Object error) {
  if (error is Exception) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.isNotEmpty) return message;
  }
  return 'Invalid username or password.';
}
