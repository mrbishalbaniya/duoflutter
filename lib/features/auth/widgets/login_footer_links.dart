import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// Footer links from DuoFrontend `/login` (Privacy, Terms, Help).
class LoginFooterLinks extends StatelessWidget {
  const LoginFooterLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      // Wrap (not Row) so the three links drop to a second line on narrow phones.
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        children: [
          _FooterLink(
            label: 'Privacy Policy',
            color: scheme.onSurfaceVariant,
            onTap: () => _open(context, AppRoutes.legalPrivacy),
          ),
          _dot(scheme),
          _FooterLink(
            label: 'Terms of Service',
            color: scheme.onSurfaceVariant,
            onTap: () => _open(context, AppRoutes.legalTerms),
          ),
          _dot(scheme),
          _FooterLink(
            label: 'Help Center',
            color: scheme.onSurfaceVariant,
            onTap: () => _open(context, AppRoutes.help),
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

  void _open(BuildContext context, String route) {
    HapticFeedback.selectionClick();
    context.push(route);
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
