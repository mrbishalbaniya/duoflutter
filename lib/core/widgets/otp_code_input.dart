import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum OtpStatus { idle, error, success }

/// Six single-digit boxes with paste support, auto-advance and an error
/// shake (web `OtpInput`). Calls [onComplete] once every box is filled.
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    this.length = 6,
    this.label = 'Verification code',
    this.status = OtpStatus.idle,
    this.errorMessage = '',
    this.disabled = false,
    this.autofocus = true,
    required this.onComplete,
  });

  final int length;
  final String label;
  final OtpStatus status;
  final String errorMessage;
  final bool disabled;
  final bool autofocus;
  final ValueChanged<String> onComplete;

  @override
  State<OtpCodeInput> createState() => OtpCodeInputState();
}

class OtpCodeInputState extends State<OtpCodeInput> with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _controllers =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _nodes = List.generate(widget.length, (_) => FocusNode());
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  /// Empties every box and focuses the first one.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (!widget.disabled) _nodes.first.requestFocus();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _nodes.first.requestFocus());
    }
  }

  @override
  void didUpdateWidget(OtpCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == OtpStatus.error && oldWidget.status != OtpStatus.error) {
      _shake.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _shake.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      // Pasted or autofilled: spread across the boxes from here.
      for (var i = 0; i < digits.length && index + i < widget.length; i++) {
        _controllers[index + i].text = digits[i];
      }
      final next = math.min(index + digits.length, widget.length - 1);
      _nodes[next].requestFocus();
    } else {
      _controllers[index].text = digits;
      if (digits.isNotEmpty && index < widget.length - 1) _nodes[index + 1].requestFocus();
    }
    setState(() {});
    final code = _code;
    if (code.length == widget.length) widget.onComplete(code);
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _nodes[index - 1].requestFocus();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = widget.status == OtpStatus.error;
    final success = widget.status == OtpStatus.success;
    final border = error
        ? scheme.error
        : success
            ? const Color(0xFF22C55E)
            : scheme.outlineVariant.withValues(alpha: 0.5);

    return Semantics(
      label: widget.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value), 0),
              child: child,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  SizedBox(
                    width: 46,
                    height: 56,
                    child: Focus(
                      onKeyEvent: (_, e) => _onKey(i, e),
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _nodes[i],
                        enabled: !widget.disabled,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (v) => _onChanged(i, v),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: scheme.surfaceContainerHigh,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: border, width: error || success ? 2 : 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: error ? scheme.error : scheme.primary, width: 2),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: border),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (error && widget.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                widget.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: scheme.error, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Resend code" / "Resend code in 42s" countdown (web resend cooldown).
class ResendCountdown {
  ResendCountdown(this._onTick);

  final VoidCallback _onTick;
  int seconds = 0;
  bool _running = false;

  void start(int value) {
    seconds = value;
    _onTick();
    if (_running) return;
    _running = true;
    _loop();
  }

  Future<void> _loop() async {
    while (seconds > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!_running) return;
      seconds = math.max(0, seconds - 1);
      _onTick();
    }
    _running = false;
  }

  void stop() {
    _running = false;
    seconds = 0;
  }
}
