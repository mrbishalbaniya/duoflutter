import 'package:flutter/material.dart';

class CallControls extends StatelessWidget {
  const CallControls({
    super.key,
    required this.isVideo,
    required this.onToggleMic,
    required this.onToggleVideo,
    required this.onToggleSpeaker,
    required this.onHangup,
    this.onSwitchCamera,
  });

  final bool isVideo;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onHangup;
  final VoidCallback? onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _btn(Icons.mic, onToggleMic),
        if (isVideo) _btn(Icons.videocam, onToggleVideo),
        if (isVideo && onSwitchCamera != null) _btn(Icons.cameraswitch, onSwitchCamera!),
        _btn(Icons.volume_up, onToggleSpeaker),
        FloatingActionButton(
          backgroundColor: Colors.red,
          onPressed: onHangup,
          child: const Icon(Icons.call_end),
        ),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return FloatingActionButton(
      backgroundColor: Colors.white24,
      onPressed: onTap,
      child: Icon(icon, color: Colors.white),
    );
  }
}
