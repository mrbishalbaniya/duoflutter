import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/duo_gradients.dart';
import '../../../repositories/photo_repository.dart';
import '../registration_controller.dart';
import '../registration_models.dart';
import '../registration_validators.dart';
import '../widgets/registration_widgets.dart';

// Port of DuoFrontend `components/register/StepPhotos.tsx`: three slots, each
// upload runs on its own with live progress, errors stay in their slot with
// "Try again", and a rate-limit cooldown pauses new uploads.

/// Must match PROFILE_IMAGE_TYPES / MAX_PROFILE_UPLOAD_BYTES in the backend.
const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
const _maxPhotoBytes = 10 * 1024 * 1024;
const _verifyingWords = ['Verifying', 'Analyzing', 'Quality', 'Face', 'Content'];
const _duplicateMessage = 'You already added this photo. Choose a different one.';

enum _PendingStatus { uploading, error, rateLimited }

class _PendingUpload {
  _PendingUpload({
    required this.id,
    required this.file,
    required this.fileName,
    required this.fingerprint,
    required this.idempotencyKey,
  });

  final String id;
  final File file;
  final String fileName;
  final String fingerprint;

  /// Reused on every retry so the server can replay a finished result.
  final String idempotencyKey;
  _PendingStatus status = _PendingStatus.uploading;

  /// 0..1 while bytes are sent; at 1 the server is running AI verification.
  double progress = 0;
  String? errorMessage;
  bool retryable = true;
}

String _newIdempotencyKey() {
  final r = math.Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

String _formatWait(int seconds) {
  final s = math.max(0, seconds);
  if (s < 60) return '${s}s';
  final minutes = (s / 60).ceil();
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

({String title, IconData icon}) _describeFailure(String message, bool rateLimited) {
  final m = message.toLowerCase();
  if (rateLimited) return (title: 'Upload limit reached', icon: Icons.schedule_rounded);
  if (m.contains('explicit') || m.contains('nsfw') || m.contains('inappropriate')) {
    return (title: 'Not allowed', icon: Icons.block_rounded);
  }
  if (m.contains('already added') || m.contains('duplicate')) {
    return (title: 'Already uploaded', icon: Icons.content_copy_rounded);
  }
  if (m.contains('face')) return (title: 'No face detected', icon: Icons.face_retouching_off_rounded);
  if (m.contains('blur') || m.contains('resolution') || m.contains('quality')) {
    return (title: 'Low quality photo', icon: Icons.blur_on_rounded);
  }
  if (m.contains('type') || m.contains('format') || m.contains('size') || m.contains('empty') || m.contains('large')) {
    return (title: 'Unsupported file', icon: Icons.insert_drive_file_outlined);
  }
  return (title: 'Upload failed', icon: Icons.error_outline_rounded);
}

class StepPhotos extends ConsumerStatefulWidget {
  const StepPhotos({super.key, required this.onContinue, required this.onBack});

  final Future<void> Function() onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<StepPhotos> createState() => _StepPhotosState();
}

class _StepPhotosState extends ConsumerState<StepPhotos> {
  late List<RegistrationPhoto> _photos;
  final List<_PendingUpload> _pending = [];
  final Map<String, String> _photoFingerprints = {};
  final _picker = ImagePicker();
  String? _error;
  bool _picking = false;

  DateTime? _cooldownUntil;
  Timer? _cooldownTimer;
  Timer? _tickerTimer;
  int _tickerIndex = 0;

  @override
  void initState() {
    super.initState();
    _photos = ref
        .read(registrationControllerProvider)
        .data
        .photos
        .take(maxRegistrationPhotos)
        .toList();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _tickerTimer?.cancel();
    super.dispose();
  }

  int get _cooldownSeconds {
    final until = _cooldownUntil;
    if (until == null) return 0;
    return math.max(0, (until.difference(DateTime.now()).inMilliseconds / 1000).ceil());
  }

  bool get _inCooldown => _cooldownSeconds > 0;
  bool get _anyUploading => _pending.any((p) => p.status == _PendingStatus.uploading);
  int get _freeSlots => maxRegistrationPhotos - _photos.length - _pending.length;

  void _setPhotos(List<RegistrationPhoto> photos) {
    if (!mounted) return;
    setState(() => _photos = photos);
    ref.read(registrationControllerProvider.notifier).patchData((d) => d.copyWith(photos: photos));
  }

  void _syncTicker() {
    if (_anyUploading && _tickerTimer == null) {
      _tickerTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        if (mounted) setState(() => _tickerIndex = (_tickerIndex + 1) % _verifyingWords.length);
      });
    } else if (!_anyUploading) {
      _tickerTimer?.cancel();
      _tickerTimer = null;
    }
  }

  void _startCooldown(int seconds) {
    final until = DateTime.now().add(Duration(seconds: math.max(1, seconds)));
    if (_cooldownUntil != null && _cooldownUntil!.isAfter(until)) return;
    _cooldownUntil = until;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (!_inCooldown) {
        timer.cancel();
        _cooldownUntil = null;
        // The wait is over: rate-limited photos can be retried again.
        for (final p in _pending.where((p) => p.status == _PendingStatus.rateLimited)) {
          p
            ..status = _PendingStatus.error
            ..errorMessage = 'Ready to retry.'
            ..retryable = true;
        }
      }
      setState(() {});
    });
  }

  String? _validateFile(File file, String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (!_allowedExtensions.contains(ext)) return 'Please choose a JPG, PNG, WebP or GIF image.';
    final size = file.lengthSync();
    if (size == 0) return 'This file is empty. Please choose another photo.';
    if (size > _maxPhotoBytes) {
      return 'This photo is too large. The maximum size is ${_maxPhotoBytes ~/ (1024 * 1024)} MB.';
    }
    return null;
  }

  Future<String> _fingerprint(File file) async => md5.convert(await file.readAsBytes()).toString();

  Future<void> _pickPhotos() async {
    if (_picking || _inCooldown || _freeSlots <= 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final free = _freeSlots;
      // pickMultiImage needs limit >= 2; a single free slot uses the single picker.
      final files = free >= 2
          ? await _picker.pickMultiImage(imageQuality: 90, limit: free)
          : [if (await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90) case final f?) f];
      if (!mounted || files.isEmpty) return;
      if (files.length > free) {
        _toast('Only $maxRegistrationPhotos photos are allowed. Added the first $free.');
      }

      // Uploads need a signed-in account; recreate the session if it was lost.
      final signedIn = await ref.read(registrationControllerProvider.notifier).ensureAccount();
      if (!mounted) return;
      if (!signedIn) {
        setState(() => _error = ref.read(registrationControllerProvider).error ??
            'Sign in and complete account setup (steps 1–2) before uploading photos.');
        return;
      }

      final known = {
        ..._photoFingerprints.values,
        ..._pending.where((p) => p.status != _PendingStatus.error).map((p) => p.fingerprint),
      };
      final toUpload = <_PendingUpload>[];
      for (final x in files.take(math.max(0, _freeSlots))) {
        final file = File(x.path);
        final pending = _PendingUpload(
          id: '${DateTime.now().microsecondsSinceEpoch}-${x.name}',
          file: file,
          fileName: x.name,
          fingerprint: await _fingerprint(file),
          idempotencyKey: _newIdempotencyKey(),
        );
        // Bad files and duplicates never reach the server (web parity).
        final fileError = _validateFile(file, x.name);
        final duplicate = known.contains(pending.fingerprint);
        if (fileError != null || duplicate) {
          pending
            ..status = _PendingStatus.error
            ..errorMessage = fileError ?? _duplicateMessage
            ..retryable = false;
        } else {
          known.add(pending.fingerprint);
          toUpload.add(pending);
        }
        _pending.add(pending);
      }
      setState(() {});
      // Each photo uploads and verifies on its own, in parallel.
      for (final p in toUpload) {
        unawaited(_runUpload(p));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _runUpload(_PendingUpload pending) async {
    // Never send a request while rate-limited: it would fail and extend the wait.
    if (_inCooldown) {
      setState(() {
        pending
          ..status = _PendingStatus.rateLimited
          ..errorMessage = 'Upload limit reached.';
      });
      return;
    }
    setState(() {
      pending
        ..status = _PendingStatus.uploading
        ..progress = 0
        ..errorMessage = null;
      _syncTicker();
    });

    try {
      // First photo in line becomes the profile photo when none is set yet.
      final isPrimary = !_photos.any((p) => p.isProfile) && _pending.indexOf(pending) == 0;
      final result = await ref.read(photoRepositoryProvider).uploadAndAnalyzePhoto(
            pending.file,
            isPrimary: isPrimary,
            idempotencyKey: pending.idempotencyKey,
            onSendProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              setState(() => pending.progress = (sent / total).clamp(0, 1));
            },
          );
      final uploadError = getPhotoUploadError(result);
      if (uploadError != null) throw Exception(uploadError);
      if (!mounted) return;

      final photo = RegistrationPhoto(
        id: pending.id,
        fileName: pending.fileName,
        localPath: pending.file.path,
        isProfile: !_photos.any((p) => p.isProfile),
        imageUrl: result.imageUrl,
        status: RegistrationPhotoStatus.approved,
      );
      _photoFingerprints[photo.id] = pending.fingerprint;
      _pending.remove(pending);
      _setPhotos([..._photos, photo]);
      HapticFeedback.lightImpact();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 429) {
        final raw = e.raw;
        final wait = raw is Map ? (raw['retry_after'] as num?)?.ceil() : null;
        _startCooldown(wait ?? 60);
        pending
          ..status = _PendingStatus.rateLimited
          ..errorMessage = 'Upload limit reached.';
      } else {
        pending
          ..status = _PendingStatus.error
          ..errorMessage = e.message.isNotEmpty ? e.message : 'Verification failed.'
          ..retryable = true;
      }
    } catch (e) {
      if (!mounted) return;
      pending
        ..status = _PendingStatus.error
        ..errorMessage = e.toString().replaceFirst('Exception: ', '')
        ..retryable = true;
    } finally {
      if (mounted) setState(_syncTicker);
    }
  }

  void _removePending(_PendingUpload pending) {
    setState(() => _pending.remove(pending));
  }

  void _removePhoto(String id) {
    final next = _photos.where((p) => p.id != id).toList();
    if (next.isNotEmpty && !next.any((p) => p.isProfile)) {
      next[0] = next[0].copyWith(isProfile: true);
    }
    _photoFingerprints.remove(id);
    _error = null;
    _setPhotos(next);
  }

  void _setProfile(String id) {
    HapticFeedback.selectionClick();
    _setPhotos(_photos.map((p) => p.copyWith(isProfile: p.id == id)).toList());
  }

  void _toast(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_anyUploading) return;
    final error = validatePhotos(_photos);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ref.read(registrationControllerProvider.notifier).patchData((d) => d.copyWith(photos: _photos));
    await widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final approvedCount = _photos.where((p) => p.status == RegistrationPhotoStatus.approved).length;

    return RegistrationStepCard(
      title: 'Photos',
      subtitle: 'Upload up to $maxRegistrationPhotos photos. Each photo is checked instantly '
          'with AI for face, quality, and safety.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // One column, three rows (web grid-cols-1 on phones).
          for (var i = 0; i < maxRegistrationPhotos; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _slot(context, i),
          ],
          if (_inCooldown) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upload limit reached. You can upload again in ${_formatWait(_cooldownSeconds)}. '
                      'Photos you already verified are saved.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '$approvedCount of $maxRegistrationPhotos photos verified'
            ' · at least $minRegistrationPhotos required'
            '${_anyUploading ? ' · verification in progress…' : ''}',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          RegistrationFieldError(message: _error),
          if (approvedCount < minRegistrationPhotos)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _anyUploading
                          ? 'Continue appears once your photo is verified.'
                          : 'Upload at least $minRegistrationPhotos verified photo to continue.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          RegistrationStepNavigation(
            onBack: widget.onBack,
            onNext: _submit,
            // Continue only shows once at least one photo passed verification.
            showNext: approvedCount >= minRegistrationPhotos,
            loading: _anyUploading,
            nextLabel: _anyUploading ? 'Analyzing…' : 'Continue',
          ),
        ],
      ),
    );
  }

  /// Slots fill left to right: verified photos, then uploads in flight, then empty.
  Widget _slot(BuildContext context, int index) {
    if (index < _photos.length) return _photoCard(context, _photos[index]);
    final pendingIndex = index - _photos.length;
    if (pendingIndex < _pending.length) return _pendingCard(context, _pending[pendingIndex]);
    return _emptySlot(context, isNext: index == _photos.length + _pending.length);
  }

  Widget _frame({required Widget child, Color? border, double borderWidth = 1}) {
    return AspectRatio(
      // Full-width rows: landscape cards keep the three slots on about one screen.
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border ?? Colors.transparent, width: borderWidth),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
      ),
    );
  }

  Widget _emptySlot(BuildContext context, {required bool isNext}) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = _inCooldown || _picking;
    return _frame(
      border: scheme.primary.withValues(alpha: isNext ? 0.35 : 0.15),
      borderWidth: 1.5,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        child: InkWell(
          onTap: disabled ? null : _pickPhotos,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _inCooldown ? Icons.hourglass_top_rounded : Icons.add_a_photo_outlined,
                size: 36,
                color: disabled ? scheme.onSurfaceVariant : scheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                _inCooldown ? 'Wait ${_formatWait(_cooldownSeconds)}' : 'Upload',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pendingCard(BuildContext context, _PendingUpload pending) {
    final scheme = Theme.of(context).colorScheme;
    final uploading = pending.status == _PendingStatus.uploading;
    final sending = uploading && pending.progress < 1;
    final percent = (pending.progress * 100).round();

    return _frame(
      border: uploading ? scheme.primary.withValues(alpha: 0.5) : scheme.error.withValues(alpha: 0.5),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(pending.file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
          ColoredBox(color: Colors.black.withValues(alpha: uploading ? 0.45 : 0.65)),
          if (uploading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          // Determinate while sending; indeterminate while the AI checks run.
                          value: sending ? pending.progress : null,
                          strokeWidth: 3,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                        if (sending)
                          Text('$percent%',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sending ? 'Uploading' : '${_verifyingWords[_tickerIndex]}…',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: sending ? pending.progress : null,
                      minHeight: 5,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ],
              ),
            )
          else
            _failurePanel(pending),
          if (!uploading) _removeButton(() => _removePending(pending)),
        ],
      ),
    );
  }

  Widget _failurePanel(_PendingUpload pending) {
    final rateLimited = pending.status == _PendingStatus.rateLimited;
    final message = pending.errorMessage ?? '';
    final info = _describeFailure(message, rateLimited);
    final canRetry = pending.retryable && !rateLimited;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(info.icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(
            info.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
            ),
          ),
          if (canRetry || rateLimited) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 34,
              child: FilledButton.tonal(
                onPressed: _inCooldown ? null : () => _runUpload(pending),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: Text(_inCooldown ? 'Retry in ${_formatWait(_cooldownSeconds)}' : 'Try again'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _removeButton(VoidCallback onTap) {
    return Positioned(
      top: 8,
      right: 8,
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _photoCard(BuildContext context, RegistrationPhoto photo) {
    final scheme = Theme.of(context).colorScheme;
    final approved = photo.status == RegistrationPhotoStatus.approved;
    final local = photo.localPath != null && File(photo.localPath!).existsSync();

    return _frame(
      border: photo.isProfile ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.3),
      borderWidth: photo.isProfile ? 2 : 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          local
              ? Image.file(File(photo.localPath!), fit: BoxFit.cover)
              : photo.imageUrl != null
                  ? Image.network(photo.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(color: scheme.surfaceContainerHighest))
                  : ColoredBox(color: scheme.surfaceContainerHighest),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
                stops: [0.55, 1],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: approved ? Colors.green.shade600 : scheme.error,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(approved ? Icons.verified_rounded : Icons.error_outline_rounded,
                      size: 13, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    approved ? 'Verified' : 'Rejected',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          _removeButton(() => _removePhoto(photo.id)),
          Positioned(
            left: 10,
            bottom: 10,
            child: photo.isProfile
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: DuoGradients.brand,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Profile photo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  )
                : InkWell(
                    onTap: () => _setProfile(photo.id),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Set profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
