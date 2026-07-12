import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/chat_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../chat_utils.dart';
import 'voice_input_button.dart';
import 'voice_recording_bar.dart';

const _kComposerAnimDuration = Duration(milliseconds: 240);
const _kComposerAnimCurve = Curves.easeOutCubic;
const _kActionButtonSize = 40.0;
const _kActionIconSize = 22.0;

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
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _isFocused = false;
  bool _attachmentsExpanded = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVoiceComposeActive && !widget.isVoiceComposeActive) {
      _attachmentsExpanded = false;
    }
    if (oldWidget.replyingTo == null && widget.replyingTo != null) {
      _collapseAttachments();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (focused == _isFocused) return;
    setState(() {
      _isFocused = focused;
      if (focused) {
        _attachmentsExpanded = false;
      } else if (!widget.controller.text.trim().isNotEmpty) {
        _attachmentsExpanded = false;
      }
    });
  }

  void _onTextChanged() {
    final next = widget.controller.text.trim().isNotEmpty;
    if (next == _hasText) return;
    setState(() {
      _hasText = next;
      if (next) {
        _attachmentsExpanded = false;
      } else if (!_isFocused) {
        _attachmentsExpanded = false;
      }
    });
  }

  void _collapseAttachments() {
    if (_attachmentsExpanded) {
      setState(() => _attachmentsExpanded = false);
    }
  }

  bool get _isTypingActive => _isFocused || _hasText;
  bool get _busy => widget.sending || widget.uploading;

  void _keepFocusAnd(VoidCallback? action) {
    if (action == null || _busy) return;
    action();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _toggleAttachments() {
    if (_busy) return;
    HapticFeedback.lightImpact();
    setState(() => _attachmentsExpanded = !_attachmentsExpanded);
  }

  void _handleSend() {
    if (_busy || !_hasText) return;
    widget.onSend();
    _collapseAttachments();
  }

  void _handleEmoji(String emoji) {
    widget.onEmojiSelected?.call(emoji);
    _collapseAttachments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.replyingTo != null)
                          _ReplyBanner(
                            replyingTo: widget.replyingTo!,
                            onCancelReply: widget.onCancelReply,
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _LeadingActions(
                              isVoiceComposeActive: widget.isVoiceComposeActive,
                              isTypingActive: _isTypingActive,
                              attachmentsExpanded: _attachmentsExpanded,
                              busy: _busy,
                              uploading: widget.uploading,
                              isRecording: widget.isRecording,
                              voiceDraftReady: widget.voiceDraftReady,
                              onToggleAttachments: _toggleAttachments,
                              onPickCamera: () => _keepFocusAnd(widget.onPickCamera),
                              onPickImage: () => _keepFocusAnd(widget.onPickImage),
                              onVoiceListeningChange: widget.onVoiceListeningChange,
                              onCancelVoiceRecording: widget.onCancelVoiceRecording,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InputPill(
                                focusNode: _focusNode,
                                isVoiceComposeActive: widget.isVoiceComposeActive,
                                isRecording: widget.isRecording,
                                voiceRecordingSeconds: widget.voiceRecordingSeconds,
                                controller: widget.controller,
                                replyingTo: widget.replyingTo,
                                busy: _busy,
                                showEmojiPicker: widget.showEmojiPicker,
                                onTyping: widget.onTyping,
                                onSend: _handleSend,
                                onToggleEmojiPicker: () {
                                  _collapseAttachments();
                                  widget.onToggleEmojiPicker?.call();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            _TrailingAction(
                              isVoiceComposeActive: widget.isVoiceComposeActive,
                              isTypingActive: _isTypingActive,
                              hasText: _hasText,
                              busy: _busy,
                              uploading: widget.uploading,
                              onSend: _handleSend,
                              onSendVoiceMessage: widget.onSendVoiceMessage,
                              onStartVoice: () {
                                if (_busy) return;
                                HapticFeedback.mediumImpact();
                                widget.onVoiceListeningChange?.call(true);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.showEmojiPicker)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 72,
                  child: _EmojiPickerPanel(onEmojiSelected: _handleEmoji),
                ),
            ],
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
    required this.uploading,
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
  final bool uploading;
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ExpandButton(
          expanded: attachmentsExpanded,
          onPressed: busy ? null : onToggleAttachments,
        ),
        AnimatedSize(
          duration: _kComposerAnimDuration,
          curve: _kComposerAnimCurve,
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.hardEdge,
          child: attachmentsExpanded
              ? _AttachmentStrip(
                  busy: busy,
                  uploading: uploading,
                  isRecording: isRecording,
                  voiceDraftReady: voiceDraftReady,
                  onPickCamera: onPickCamera,
                  onPickImage: onPickImage,
                  onVoiceListeningChange: onVoiceListeningChange,
                )
              : const SizedBox.shrink(),
        ),
        AnimatedSwitcher(
          duration: _kComposerAnimDuration,
          switchInCurve: _kComposerAnimCurve,
          switchOutCurve: _kComposerAnimCurve,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              axis: Axis.horizontal,
              sizeFactor: animation,
              child: child,
            ),
          ),
          child: !isTypingActive
              ? Row(
                  key: const ValueKey('idle-attachments'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircleIconButton(
                      icon: Icons.photo_camera_outlined,
                      onPressed: busy ? null : onPickCamera,
                      tooltip: 'Take photo with camera',
                    ),
                    _CircleIconButton(
                      icon: uploading ? Icons.hourglass_top : Icons.image_outlined,
                      onPressed: busy ? null : onPickImage,
                      tooltip: 'Choose image from gallery',
                    ),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('typing-attachments')),
        ),
      ],
    );
  }
}

class _AttachmentStrip extends StatefulWidget {
  const _AttachmentStrip({
    required this.busy,
    required this.uploading,
    required this.isRecording,
    required this.voiceDraftReady,
    required this.onPickCamera,
    required this.onPickImage,
    required this.onVoiceListeningChange,
  });

  final bool busy;
  final bool uploading;
  final bool isRecording;
  final bool voiceDraftReady;
  final VoidCallback? onPickCamera;
  final VoidCallback? onPickImage;
  final ValueChanged<bool>? onVoiceListeningChange;

  @override
  State<_AttachmentStrip> createState() => _AttachmentStripState();
}

class _AttachmentStripState extends State<_AttachmentStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kComposerAnimDuration);
    _fade = CurvedAnimation(parent: _controller, curve: _kComposerAnimCurve);
    _slide = Tween<Offset>(begin: const Offset(-0.12, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: _kComposerAnimCurve));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CircleIconButton(
              icon: Icons.photo_camera_outlined,
              onPressed: widget.busy ? null : widget.onPickCamera,
              tooltip: 'Take photo with camera',
            ),
            _CircleIconButton(
              icon: widget.uploading ? Icons.hourglass_top : Icons.image_outlined,
              onPressed: widget.busy ? null : widget.onPickImage,
              tooltip: 'Choose image from gallery',
            ),
            VoiceInputButton(
              listening: widget.isRecording,
              paused: widget.voiceDraftReady && !widget.isRecording,
              disabled: widget.busy,
              onListeningChange: widget.onVoiceListeningChange ?? (_) {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({
    required this.expanded,
    required this.onPressed,
  });

  final bool expanded;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _CircleIconButton(
      onPressed: onPressed,
      tooltip: expanded
          ? 'Hide attachment options'
          : 'Show attachment options',
      child: AnimatedRotation(
        turns: expanded ? 0.5 : 0,
        duration: _kComposerAnimDuration,
        curve: _kComposerAnimCurve,
        child: Icon(
          Icons.chevron_right_rounded,
          size: _kActionIconSize,
          color: DuoColors.primary,
        ),
      ),
    );
  }
}

class _InputPill extends StatelessWidget {
  const _InputPill({
    required this.focusNode,
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

  final FocusNode focusNode;
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
    final focused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: _kComposerAnimDuration,
      curve: _kComposerAnimCurve,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isVoiceComposeActive
              ? DuoColors.primary.withValues(alpha: 0.2)
              : focused
                  ? DuoColors.primary.withValues(alpha: 0.55)
                  : scheme.outlineVariant.withValues(alpha: 0.4),
          width: focused && !isVoiceComposeActive ? 1.5 : 1,
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
                    focusNode: focusNode,
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !busy,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    scrollPadding: const EdgeInsets.only(bottom: 96),
                    onChanged: (_) => onTyping(),
                    onSubmitted: (_) => onSend(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: replyingTo != null ? 'Write a reply…' : 'Aa',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                _CircleIconButton(
                  icon: showEmojiPicker
                      ? Icons.keyboard_rounded
                      : Icons.sentiment_satisfied_alt_outlined,
                  onPressed: busy ? null : onToggleEmojiPicker,
                  tooltip: showEmojiPicker ? 'Hide emoji picker' : 'Add emoji',
                  iconColor: DuoColors.primary,
                ),
              ],
            ),
    );
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({
    required this.isVoiceComposeActive,
    required this.isTypingActive,
    required this.hasText,
    required this.busy,
    required this.uploading,
    required this.onSend,
    required this.onSendVoiceMessage,
    required this.onStartVoice,
  });

  final bool isVoiceComposeActive;
  final bool isTypingActive;
  final bool hasText;
  final bool busy;
  final bool uploading;
  final VoidCallback onSend;
  final VoidCallback? onSendVoiceMessage;
  final VoidCallback onStartVoice;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _kComposerAnimDuration,
      switchInCurve: _kComposerAnimCurve,
      switchOutCurve: _kComposerAnimCurve,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isVoiceComposeActive
          ? _SendCircleButton(
              key: const ValueKey('send-voice'),
              onPressed: busy ? null : onSendVoiceMessage,
              tooltip: 'Send voice message',
            )
          : isTypingActive
              ? _SendCircleButton(
                  key: const ValueKey('send-text'),
                  onPressed: busy || !hasText ? null : onSend,
                  tooltip: 'Send message',
                  showProgress: busy && !uploading,
                  dimmed: !hasText,
                )
              : _MicTrailingButton(
                  key: const ValueKey('mic'),
                  disabled: busy,
                  onPressed: onStartVoice,
                ),
    );
  }
}

class _MicTrailingButton extends StatelessWidget {
  const _MicTrailingButton({
    super.key,
    required this.disabled,
    required this.onPressed,
  });

  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Record voice message',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: _kActionButtonSize,
            height: _kActionButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              Icons.mic_rounded,
              size: _kActionIconSize,
              color: disabled
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
                  : DuoColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SendCircleButton extends StatelessWidget {
  const _SendCircleButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
    this.showProgress = false,
    this.dimmed = false,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final bool showProgress;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !dimmed;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            width: _kActionButtonSize,
            height: _kActionButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  DuoColors.primary.withValues(alpha: dimmed ? 0.45 : 1),
                  DuoColors.primaryContainer.withValues(alpha: dimmed ? 0.45 : 1),
                ],
              ),
              boxShadow: enabled
                  ? const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: showProgress
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: Colors.white.withValues(alpha: dimmed ? 0.7 : 1),
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmojiPickerPanel extends StatefulWidget {
  const _EmojiPickerPanel({required this.onEmojiSelected});

  final ValueChanged<String> onEmojiSelected;

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
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(16),
      color: scheme.surface,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: composerEmojis.length,
          itemBuilder: (_, i) {
            final emoji = composerEmojis[i];
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => widget.onEmojiSelected(emoji),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    this.icon,
    required this.onPressed,
    required this.tooltip,
    this.child,
    this.iconColor,
  }) : assert(icon != null || child != null);

  final IconData? icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Widget? child;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: _kActionButtonSize,
        height: _kActionButtonSize,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: child ??
              Icon(
                icon,
                color: iconColor ?? DuoColors.primary,
                size: _kActionIconSize,
              ),
        ),
      ),
    );
  }
}
