import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && !loading && onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF131314),
          foregroundColor: const Color(0xFFE3E3E3),
          side: const BorderSide(color: Color(0xFF747775)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w700,
          fontSize: 13,
          height: 1,
        ),
      ),
    );
  }
}
