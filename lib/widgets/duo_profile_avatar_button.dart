import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/media/media_url.dart';
import '../core/router/app_router.dart';
import '../core/theme/theme_extensions.dart';
import '../features/auth/auth_controller.dart';

/// Small avatar of the signed-in user shown at the top-left of the main tabs;
/// tapping it opens the Profile tab.
class DuoProfileAvatarButton extends ConsumerWidget {
  const DuoProfileAvatarButton({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider.select((s) => s.user?.profile));
    final scheme = Theme.of(context).colorScheme;
    final url = profile == null ? '' : resolveProfilePhotoUrl(profile);
    final name = profile?.displayName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Semantics(
      button: true,
      label: 'Your profile',
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.profile),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: context.duo.brandGradient,
            boxShadow: [BoxShadow(color: context.duo.cardShadow, blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: ClipOval(
            child: ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: url.isEmpty
                  ? Center(
                      child: Text(initial, style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700)),
                    )
                  : CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                      errorWidget: (_, __, ___) => Center(
                        child: Text(initial, style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700)),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
