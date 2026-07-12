import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../chat_utils.dart';
import 'voice_input_button.dart';
import 'voice_recording_bar.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onTyping,
    this.replyingTo,
    this.onCancelReply,
    this.onPickImage,
    this.onPickCamera,
    this.showEmojiPicker = false,
    this.onToggleEmojiPicker,
    this.onEmojiSelected,
    this.sending = false,
    this.uploading = false,
    this.isVoiceComposeActive = false,
    this.isRecording = false,
    this.voiceDraftReady = false,
    this.voiceRecordingSeconds = 0,
    this.onVoiceListeningChange,
    this.onCancelVoiceRecording,
    this.onSendVoiceMessage,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onTyping;
  final ChatMessage? replyingTo;
  final VoidCallback? onCancelReply;
  final VoidCallback? onPickImage;
  final VoidCallback? onPickCamera;
  final bool showEmojiPicker;
  final VoidCallback? onToggleEmojiPicker;
  final ValueChanged<String>? onEmojiSelected;
  final bool sending;
  final bool uploading;
  final bool isVoiceComposeActive;
  final bool isRecording;
  final bool voiceDraftReady;
  final int voiceRecordingSeconds;
  final ValueChanged<bool>? onVoiceListeningChange;
  final VoidCallback? onCancelVoiceRecording;
  final VoidCallback? onSendVoiceMessage;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  bool _hasText = false;
  bool _attachmentsExpanded = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVoiceComposeActive && !widget.isVoiceComposeActive) {
      _attachmentsExpanded = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final next = widget.controller.text.trim().isNotEmpty;
    if (next != _hasText) {
      setState(() => _hasText = next);
    }
  }

  bool get _isTypingActive => _hasText;
  bool get _busy => widget.sending || widget.uploading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.35))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.replyingTo != null) _ReplyBanner(
                replyingTo: widget.replyingTo!,
                onCancelReply: widget.onCancelReply,
              ),
              if (widget.showEmojiPicker)
                _EmojiPickerPanel(onEmojiSelected: widget.onEmojiSelected),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _LeadingActions(
                    isVoiceComposeActive: widget.isVoiceComposeActive,
                    isTypingActive: _isTypingActive,
                    attachmentsExpanded: _attachmentsExpanded,
                    busy: _busy,
                    isRecording: widget.isRecording,
                    voiceDraftReady: widget.voiceDraftReady,
                    onToggleAttachments: () {
                      setState(() => _attachmentsExpanded = !_attachmentsExpanded);
                    },
                    onPickCamera: widget.onPickCamera,
                    onPickImage: widget.onPickImage,
                    onVoiceListeningChange: widget.onVoiceListeningChange,
                    onCancelVoiceRecording: widget.onCancelVoiceRecording,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _InputPill(
                    isVoiceComposeActive: widget.isVoiceComposeActive,
                    isRecording: widget.isRecording,
                    voiceRecordingSeconds: widget.voiceRecordingSeconds,
                    controller: widget.controller,
                    replyingTo: widget.replyingTo,
                    busy: _busy,
                    showEmojiPicker: widget.showEmojiPicker,
                    onTyping: widget.onTyping,
                    onSend: widget.onSend,
                    onToggleEmojiPicker: widget.onToggleEmojiPicker,
                  )),
                  const SizedBox(width: 8),
                  _TrailingAction(
                    isVoiceComposeActive: widget.isVoiceComposeActive,
                    hasText: _hasText,
                    busy: _busy,
                    uploading: widget.uploading,
                    onSend: widget.onSend,
                    onSendVoiceMessage: widget.onSendVoiceMessage,
                    onVoiceListeningChange: widget.onVoiceListeningChange,
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

class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({
    required this.replyingTo,
    required this.onCancelReply,
  });

  final ChatMessage replyingTo;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DuoColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DuoColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${replyingTo.senderName ?? 'message'}',
                  style: const TextStyle(
                    color: DuoColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  replyPreview(replyingTo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancelReply,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class _LeadingActions extends StatelessWidget {
  const _LeadingActions({
    required this.isVoiceComposeActive,
    required this.isTypingActive,
    required this.attachmentsExpanded,
    required this.busy,
    required this.isRecording,
    required this.voiceDraftReady,
    required this.onToggleAttachments,
    required this.onPickCamera,
    required this.onPickImage,
    required this.onVoiceListeningChange,
    required this.onCancelVoiceRecording,
  });

  final bool isVoiceComposeActive;
  final bool isTypingActive;
  final bool attachmentsExpanded;
  final bool busy;
  final bool isRecording;
  final bool voiceDraftReady;
  final VoidCallback onToggleAttachments;
  final VoidCallback? onPickCamera;
  final VoidCallback? onPickImage;
  final ValueChanged<bool>? onVoiceListeningChange;
  final VoidCallback? onCancelVoiceRecording;

  @override
  Widget build(BuildContext context) {
    if (isVoiceComposeActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CircleIconButton(
            icon: Icons.delete_outline,
            onPressed: busy ? null : onCancelVoiceRecording,
            tooltip: 'Cancel voice recording',
          ),
          VoiceInputButton(
            listening: isRecording,
            paused: voiceDraftReady && !isRecording,
            disabled: busy,
            onListeningChange: onVoiceListeningChange ?? (_) {},
          ),
        ],
      );
    }

    if (isTypingActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CircleIconButton(
            icon: attachmentsExpanded ? Icons.expand_more : Icons.chevron_right,
            onPressed: busy ? null : onToggleAttachments,
            tooltip: attachmentsExpanded
                ? 'Hide camera, image, and voice options'
                : 'Show camera, image, and voice options',
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: attachmentsExpanded
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CircleIconButton(
                        icon: Icons.photo_camera_outlined,
                        onPressed: busy ? null : onPickCamera,
                        tooltip: 'Take photo with camera',
                      ),
                      _CircleIconButton(
                        icon: busy ? Icons.hourglass_top : Icons.image_outlined,
                        onPressed: busy ? null : onPickImage,
                        tooltip: 'Choose image from gallery',
                      ),
                      VoiceInputButton(
                        listening: isRecording,
                        paused: voiceDraftReady && !isRecording,
                        disabled: busy,
                        onListeningChange: onVoiceListeningChange ?? (_) {},
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleIconButton(
          icon: Icons.photo_camera_outlined,
          onPressed: busy ? null : onPickCamera,
          tooltip: 'Take photo with camera',
        ),
        _CircleIconButton(
          icon: busy ? Icons.hourglass_top : Icons.image_outlined,
          onPressed: busy ? null : onPickImage,
          tooltip: 'Choose image from gallery',
        ),
        VoiceInputButton(
          listening: isRecording,
          paused: voiceDraftReady && !isRecording,
          disabled: busy,
          onListeningChange: onVoiceListeningChange ?? (_) {},
        ),
      ],
    );
  }
}

class _InputPill extends StatelessWidget {
  const _InputPill({
    required this.isVoiceComposeActive,
    required this.isRecording,
    required this.voiceRecordingSeconds,
    required this.controller,
    required this.replyingTo,
    required this.busy,
    required this.showEmojiPicker,
    required this.onTyping,
    required this.onSend,
    required this.onToggleEmojiPicker,
  });

  final bool isVoiceComposeActive;
  final bool isRecording;
  final int voiceRecordingSeconds;
  final TextEditingController controller;
  final ChatMessage? replyingTo;
  final bool busy;
  final bool showEmojiPicker;
  final VoidCallback onTyping;
  final VoidCallback onSend;
  final VoidCallback? onToggleEmojiPicker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isVoiceComposeActive
              ? DuoColors.primary.withValues(alpha: 0.2)
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: isVoiceComposeActive
          ? VoiceRecordingBar(
              active: isRecording,
              seconds: voiceRecordingSeconds,
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !busy,
                    onChanged: (_) => onTyping(),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: replyingTo != null ? 'Write a reply…' : 'Aa',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleEmojiPicker,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    showEmojiPicker ? Icons.keyboard : Icons.sentiment_satisfied_alt_outlined,
                    size: 20,
                    color: DuoColors.primary,
                  ),
                ),
              ],
            ),
    );
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({
    required this.isVoiceComposeActive,
    required this.hasText,
    required this.busy,
    required this.uploading,
    required this.onSend,
    required this.onSendVoiceMessage,
    required this.onVoiceListeningChange,
  });

  final bool isVoiceComposeActive;
  final bool hasText;
  final bool busy;
  final bool uploading;
  final VoidCallback onSend;
  final VoidCallback? onSendVoiceMessage;
  final ValueChanged<bool>? onVoiceListeningChange;

  @override
  Widget build(BuildContext context) {
    if (isVoiceComposeActive) {
      return _SendCircleButton(
        onPressed: busy ? null : onSendVoiceMessage,
        tooltip: 'Send voice message',
      );
    }

    if (hasText) {
      return _SendCircleButton(
        onPressed: busy ? null : onSend,
        tooltip: 'Send message',
        showProgress: busy && !uploading,
      );
    }

    return VoiceInputButton(
      listening: false,
      paused: false,
      disabled: busy,
      onListeningChange: (next) {
        if (next) {
          HapticFeedback.mediumImpact();
          onVoiceListeningChange?.call(true);
        }
      },
    );
  }
}

class _SendCircleButton extends StatelessWidget {
  const _SendCircleButton({
    required this.onPressed,
    required this.tooltip,
    this.showProgress = false,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [DuoColors.primary, DuoColors.primaryContainer],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: showProgress
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _EmojiPickerPanel extends StatefulWidget {
  const _EmojiPickerPanel({this.onEmojiSelected});

  final ValueChanged<String>? onEmojiSelected;

  @override
  State<_EmojiPickerPanel> createState() => _EmojiPickerPanelState();
}

class _EmojiPickerPanelState extends State<_EmojiPickerPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(
      height: 120,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: composerEmojis.length,
        itemBuilder: (_, i) {
          final emoji = composerEmojis[i];
          return InkWell(
            onTap: () => widget.onEmojiSelected?.call(emoji),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          );
        },
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: DuoColors.primary),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
