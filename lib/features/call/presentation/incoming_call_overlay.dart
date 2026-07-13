import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/call_providers.dart';

class IncomingCallOverlay extends ConsumerWidget {
  const IncomingCallOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callControllerProvider);
    if (call.phase != CallPhase.incoming && call.phase != CallPhase.outgoing) {
      return const SizedBox.shrink();
    }

    final label = call.isVideo ? 'Video call' : 'Voice call';
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: call.remotePhoto != null && call.remotePhoto!.isNotEmpty
                    ? NetworkImage(call.remotePhoto!)
                    : null,
                child: call.remotePhoto == null || call.remotePhoto!.isEmpty
                    ? Text(call.remoteName.isNotEmpty ? call.remoteName[0] : '?')
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                call.phase == CallPhase.incoming ? 'Incoming $label' : 'Calling…',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                call.remoteName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (call.phase == CallPhase.incoming) ...[
                    FloatingActionButton.large(
                      backgroundColor: Colors.red,
                      onPressed: () => ref.read(callControllerProvider.notifier).rejectIncoming(),
                      child: const Icon(Icons.call_end),
                    ),
                    FloatingActionButton.large(
                      backgroundColor: Colors.green,
                      onPressed: () => ref.read(callControllerProvider.notifier).acceptIncoming(),
                      child: const Icon(Icons.call),
                    ),
                  ] else
                    FloatingActionButton.large(
                      backgroundColor: Colors.red,
                      onPressed: () => ref.read(callControllerProvider.notifier).hangup(),
                      child: const Icon(Icons.call_end),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
