import 'package:equatable/equatable.dart';

enum VerificationStatus { pending, verified, rejected, underReview }

enum LivenessStep { smile, blink, headLeft, headRight }

VerificationStatus parseVerificationStatus(String? value) {
  switch (value?.toUpperCase()) {
    case 'VERIFIED':
      return VerificationStatus.verified;
    case 'REJECTED':
      return VerificationStatus.rejected;
    case 'UNDER_REVIEW':
      return VerificationStatus.underReview;
    default:
      return VerificationStatus.pending;
  }
}

String verificationStatusToApi(VerificationStatus status) {
  switch (status) {
    case VerificationStatus.verified:
      return 'VERIFIED';
    case VerificationStatus.rejected:
      return 'REJECTED';
    case VerificationStatus.underReview:
      return 'UNDER_REVIEW';
    case VerificationStatus.pending:
      return 'PENDING';
  }
}

LivenessStep? parseLivenessStep(String? value) {
  switch (value) {
    case 'smile':
      return LivenessStep.smile;
    case 'blink':
      return LivenessStep.blink;
    case 'head_left':
      return LivenessStep.headLeft;
    case 'head_right':
      return LivenessStep.headRight;
    default:
      return null;
  }
}

String livenessStepToApi(LivenessStep step) {
  switch (step) {
    case LivenessStep.smile:
      return 'smile';
    case LivenessStep.blink:
      return 'blink';
    case LivenessStep.headLeft:
      return 'head_left';
    case LivenessStep.headRight:
      return 'head_right';
  }
}

class VerificationStartResponse extends Equatable {
  const VerificationStartResponse({
    required this.sessionId,
    required this.sessionToken,
    required this.expiresAt,
    required this.instructions,
    required this.livenessSteps,
    this.handoffUrl,
  });

  final String sessionId;
  final String sessionToken;
  final DateTime expiresAt;
  final List<String> instructions;
  final List<LivenessStep> livenessSteps;
  final String? handoffUrl;

  factory VerificationStartResponse.fromJson(Map<String, dynamic> json) {
    final steps = (json['liveness_steps'] as List<dynamic>? ?? [])
        .map((e) => parseLivenessStep(e as String?))
        .whereType<LivenessStep>()
        .toList();
    return VerificationStartResponse(
      sessionId: json['session_id'] as String? ?? json['session_token'] as String? ?? '',
      sessionToken: json['session_token'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '') ?? DateTime.now(),
      instructions: (json['instructions'] as List<dynamic>? ?? []).cast<String>(),
      livenessSteps: steps,
      handoffUrl: json['handoff_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [sessionId, sessionToken, expiresAt, instructions, livenessSteps, handoffUrl];
}

class LivenessStepResponse extends Equatable {
  const LivenessStepResponse({
    required this.step,
    required this.passed,
    required this.score,
    required this.detail,
    required this.livenessStepsCompleted,
    this.baselineCaptured = false,
  });

  final LivenessStep step;
  final bool passed;
  final double score;
  final String detail;
  final List<LivenessStep> livenessStepsCompleted;
  final bool baselineCaptured;

  factory LivenessStepResponse.fromJson(Map<String, dynamic> json) {
    final completed = (json['liveness_steps_completed'] as List<dynamic>? ?? [])
        .map((e) => parseLivenessStep(e as String?))
        .whereType<LivenessStep>()
        .toList();
    return LivenessStepResponse(
      step: parseLivenessStep(json['step'] as String?) ?? LivenessStep.smile,
      passed: json['passed'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      detail: json['detail'] as String? ?? '',
      livenessStepsCompleted: completed,
      baselineCaptured: json['baseline_captured'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [step, passed, score, detail, livenessStepsCompleted, baselineCaptured];
}

class UserVerificationSession extends Equatable {
  const UserVerificationSession({
    required this.id,
    required this.sessionToken,
    required this.similarityScore,
    required this.livenessScore,
    required this.fraudProbability,
    required this.verificationStatus,
    required this.rejectionReasons,
    required this.verifiedBadge,
    this.profilePhotoUrl,
    this.selfiePhotoUrl,
    this.livenessStepsCompleted,
    this.verifiedAt,
    this.expiresAt,
    this.createdAt,
  });

  final int id;
  final String sessionToken;
  final String? profilePhotoUrl;
  final String? selfiePhotoUrl;
  final double similarityScore;
  final double livenessScore;
  final double fraudProbability;
  final VerificationStatus verificationStatus;
  final List<LivenessStep>? livenessStepsCompleted;
  final List<String> rejectionReasons;
  final bool verifiedBadge;
  final DateTime? verifiedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  factory UserVerificationSession.fromJson(Map<String, dynamic> json) {
    final completed = (json['liveness_steps_completed'] as List<dynamic>?)
        ?.map((e) => parseLivenessStep(e as String?))
        .whereType<LivenessStep>()
        .toList();
    return UserVerificationSession(
      id: json['id'] as int? ?? 0,
      sessionToken: json['session_token'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      selfiePhotoUrl: json['selfie_photo_url'] as String?,
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0,
      livenessScore: (json['liveness_score'] as num?)?.toDouble() ?? 0,
      fraudProbability: (json['fraud_probability'] as num?)?.toDouble() ?? 0,
      verificationStatus: parseVerificationStatus(json['verification_status'] as String?),
      livenessStepsCompleted: completed,
      rejectionReasons: (json['rejection_reasons'] as List<dynamic>? ?? []).cast<String>(),
      verifiedBadge: json['verified_badge'] as bool? ?? false,
      verifiedAt: DateTime.tryParse(json['verified_at'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionToken,
        verificationStatus,
        verifiedBadge,
        livenessStepsCompleted,
      ];
}

class VerificationStatusResponse extends Equatable {
  const VerificationStatusResponse({
    required this.status,
    required this.similarityScore,
    required this.livenessScore,
    required this.fraudProbability,
    required this.verifiedBadge,
    this.rejectionReasons = const [],
    this.session,
  });

  final VerificationStatus status;
  final double similarityScore;
  final double livenessScore;
  final double fraudProbability;
  final bool verifiedBadge;
  final List<String> rejectionReasons;
  final UserVerificationSession? session;

  factory VerificationStatusResponse.fromJson(Map<String, dynamic> json) {
    return VerificationStatusResponse(
      status: parseVerificationStatus(json['status'] as String?),
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0,
      livenessScore: (json['liveness_score'] as num?)?.toDouble() ?? 0,
      fraudProbability: (json['fraud_probability'] as num?)?.toDouble() ?? 0,
      verifiedBadge: json['verified_badge'] as bool? ?? false,
      rejectionReasons: (json['rejection_reasons'] as List<dynamic>? ?? []).cast<String>(),
      session: json['session'] is Map<String, dynamic>
          ? UserVerificationSession.fromJson(json['session'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [status, similarityScore, livenessScore, fraudProbability, verifiedBadge];
}

class VerificationSessionDetail extends VerificationStatusResponse {
  const VerificationSessionDetail({
    required super.status,
    required super.similarityScore,
    required super.livenessScore,
    required super.fraudProbability,
    required super.verifiedBadge,
    required this.livenessSteps,
    required this.handoffUrl,
    required this.expiresAt,
    super.rejectionReasons,
    super.session,
  });

  final List<LivenessStep> livenessSteps;
  final String handoffUrl;
  final DateTime expiresAt;

  factory VerificationSessionDetail.fromJson(Map<String, dynamic> json) {
    final steps = (json['liveness_steps'] as List<dynamic>? ?? [])
        .map((e) => parseLivenessStep(e as String?))
        .whereType<LivenessStep>()
        .toList();
    return VerificationSessionDetail(
      status: parseVerificationStatus(json['status'] as String?),
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0,
      livenessScore: (json['liveness_score'] as num?)?.toDouble() ?? 0,
      fraudProbability: (json['fraud_probability'] as num?)?.toDouble() ?? 0,
      verifiedBadge: json['verified_badge'] as bool? ?? false,
      rejectionReasons: (json['rejection_reasons'] as List<dynamic>? ?? []).cast<String>(),
      session: json['session'] is Map<String, dynamic>
          ? UserVerificationSession.fromJson(json['session'] as Map<String, dynamic>)
          : null,
      livenessSteps: steps,
      handoffUrl: json['handoff_url'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class VerificationHandoffEmailResponse extends Equatable {
  const VerificationHandoffEmailResponse({
    required this.sent,
    required this.email,
    required this.handoffUrl,
    required this.sessionToken,
    required this.expiresAt,
  });

  final bool sent;
  final String email;
  final String handoffUrl;
  final String sessionToken;
  final DateTime expiresAt;

  factory VerificationHandoffEmailResponse.fromJson(Map<String, dynamic> json) {
    return VerificationHandoffEmailResponse(
      sent: json['sent'] as bool? ?? false,
      email: json['email'] as String? ?? '',
      handoffUrl: json['handoff_url'] as String? ?? '',
      sessionToken: json['session_token'] as String? ?? '',
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [sent, email, handoffUrl, sessionToken];
}
