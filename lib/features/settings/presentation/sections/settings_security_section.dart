import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

class SettingsSecuritySection extends ConsumerWidget {
  const SettingsSecuritySection({
    super.key,
    required this.animationIndex,
    this.visible = true,
  });

  final int animationIndex;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'Security',
      animationIndex: animationIndex,
      visible: visible,
      child: SettingsRow(
        icon: Icons.security_rounded,
        title: 'Security Center',
        description: '2FA, biometrics, devices, login history & alerts',
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(AppRoutes.security);
        },
      ),
    );
  }
}
