import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/call_providers.dart';
import 'widgets/call_controls.dart';

class ActiveCallScreen extends ConsumerWidget {
  const ActiveCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callControllerProvider);
    final webrtc = ref.read(webRtcCallServiceProvider);
    final theme = Theme.of(context);

    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundImage: call.remotePhoto != null && call.remotePhoto!.isNotEmpty
                        ? NetworkImage(call.remotePhoto!)
                        : null,
                    child: call.remotePhoto == null || call.remotePhoto!.isEmpty
                        ? Text(
                            call.remoteName.isNotEmpty ? call.remoteName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 40, color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    call.remoteName,
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${call.phase.name} · ${call.connectionQuality}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: CallControls(
                isVideo: call.isVideo,
                onToggleMic: () => webrtc.setMicrophoneEnabled(!webrtc.isAudioEnabled),
                onToggleVideo: () => webrtc.setVideoEnabled(!webrtc.isVideoEnabled),
                onSwitchCamera: call.isVideo ? () => webrtc.switchCamera() : null,
                onToggleSpeaker: () => webrtc.setSpeakerphone(!webrtc.isSpeakerOn),
                onHangup: () => ref.read(callControllerProvider.notifier).hangup(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
