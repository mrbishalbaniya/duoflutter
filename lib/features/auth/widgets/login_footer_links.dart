import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Footer links from DuoFrontend `/login` (Privacy, Terms, Help).
class LoginFooterLinks extends StatelessWidget {
  const LoginFooterLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FooterLink(
            label: 'Privacy Policy',
            color: scheme.onSurfaceVariant,
            onTap: () => _showComingSoon(context, 'Privacy Policy'),
          ),
          _dot(scheme),
          _FooterLink(
            label: 'Terms of Service',
            color: scheme.onSurfaceVariant,
            onTap: () => _showComingSoon(context, 'Terms of Service'),
          ),
          _dot(scheme),
          _FooterLink(
            label: 'Help Center',
            color: scheme.onSurfaceVariant,
            onTap: () => _showComingSoon(context, 'Help Center'),
          ),
        ],
      ),
    );
  }

  Widget _dot(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        '·',
        style: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: color.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
