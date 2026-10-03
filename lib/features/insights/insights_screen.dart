import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/media/media_url.dart';
import '../../core/models/match_models.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../widgets/duo_ui.dart';
import '../auth/auth_controller.dart';

/// All matches (for the picker when Insights is opened from Settings).
final insightsMatchesProvider = FutureProvider.autoDispose<List<MatchSession>>(
  (ref) => ref.read(matchingRepositoryProvider).getMatches(),
);

/// Port of DuoFrontend `components/chat/MatchInsightsPanel.tsx`.
///
/// Opened from a chat thread with [initialMatchId]; Navigator pops with the
/// chosen conversation starter (String) when the user taps "Use".
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key, this.initialMatchId});

  final int? initialMatchId;

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late int? _matchId = widget.initialMatchId;
  MatchSession? _match;
  DuoProfile? _otherPreview;
  Object? _error;
  bool _loading = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (_matchId != null) _load();
  }

  Future<void> _load({bool refresh = false}) async {
    final id = _matchId;
    if (id == null) return;
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final m = await ref.read(matchingRepositoryProvider).getMatchInsights(id, refresh: refresh);
      if (mounted && gen == _generation) setState(() => _match = m);
    } catch (e) {
      if (mounted && gen == _generation) setState(() => _error = e);
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  void _select(int id) {
    if (id == _matchId) return;
    setState(() {
      _matchId = id;
      _match = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).user?.profile;
    final fromChat = widget.initialMatchId != null;
    // The insights response can take a while (AI analysis); until it arrives,
    // show the person from the matches list instead of a "?" placeholder.
    final listed = ref.watch(insightsMatchesProvider).valueOrNull;
    final other = _match?.otherUserProfile ??
        listed?.where((m) => m.id == _matchId).firstOrNull?.otherUserProfile;
    final otherName = (other?.displayName.isNotEmpty ?? false) ? other!.displayName : 'Your match';
    _otherPreview = other;

    Widget body;
    if (!fromChat) {
      // Opened from Settings: pick a match first.
      final matches = ref.watch(insightsMatchesProvider);
      body = matches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DuoStateView.error(e, onRetry: () => ref.invalidate(insightsMatchesProvider)),
        data: (list) {
          if (list.isEmpty) {
            return DuoStateView(
              icon: Icons.analytics_outlined,
              title: 'No match insights yet',
              message: 'Start swiping to find matches and see compatibility insights!',
              actionLabel: 'Find Matches',
              onAction: () => context.go(AppRoutes.match),
            );
          }
          if (_matchId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _matchId == null) _select(list.first.id);
            });
          }
          return Column(
            children: [
              if (list.length > 1)
                _MatchPicker(matches: list, selectedId: _matchId, onSelect: _select),
              Expanded(child: _content(me, otherName)),
            ],
          );
        },
      );
    } else {
      body = _content(me, otherName);
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Match insights', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(
              '${me?.displayName ?? 'You'} & $otherName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (_match?.aiGenerated == true) _AiBadge(provider: _match!.aiProvider),
          if (_match != null)
            IconButton(
              tooltip: 'Refresh insights',
              onPressed: _loading ? null : () => _load(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _content(DuoProfile? me, String otherName) {
    if (_loading && _match == null || (_matchId != null && _match == null && _error == null)) {
      return _AnalysingLoader(me: me, other: _otherPreview);
    }
    if (_error != null && _match == null) {
      return DuoStateView(
        icon: Icons.cloud_off_rounded,
        title: "We couldn't load your match insights right now.",
        message: friendlyErrorMessage(_error!),
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    final m = _match;
    if (m == null) return const SizedBox.shrink();
    return Stack(
      children: [
        _InsightsBody(
          match: m,
          me: me,
          otherName: otherName,
          canUseStarters: widget.initialMatchId != null,
          onUseStarter: (s) => Navigator.of(context).pop(s),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }
}

// ---------------------------------------------------------------- helpers

({String label, Color color, IconData icon}) _verdictFor(int score) {
  if (score >= 90) return (label: 'Exceptional match', color: const Color(0xFF34D399), icon: Icons.workspace_premium);
  if (score >= 80) return (label: 'Great match', color: const Color(0xFF34D399), icon: Icons.favorite);
  if (score >= 65) return (label: 'Good match', color: const Color(0xFF38BDF8), icon: Icons.thumb_up);
  if (score >= 50) return (label: 'Promising match', color: const Color(0xFFFBBF24), icon: Icons.trending_up);
  return (label: 'Opposites attract', color: const Color(0xFFFB7185), icon: Icons.bolt);
}

String _levelFor(int v) {
  if (v >= 90) return 'Excellent';
  if (v >= 75) return 'Strong';
  if (v >= 60) return 'Good';
  if (v >= 40) return 'Moderate';
  return 'Different';
}

String? _matchedAgo(String? iso) {
  final then = DateTime.tryParse(iso ?? '');
  if (then == null) return null;
  final days = DateTime.now().difference(then).inDays;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final l = then.toLocal();
  final date = '${months[l.month - 1]} ${l.day}, ${l.year}';
  if (days <= 0) return 'Matched today';
  if (days == 1) return 'Matched yesterday';
  if (days < 30) return 'Matched $days days ago · $date';
  return 'Matched on $date';
}

IconData _interestIcon(String interest) {
  final i = interest.toLowerCase();
  bool has(List<String> keys) => keys.any(i.contains);
  if (has(['travel', 'trip', 'explor'])) return Icons.flight;
  if (has(['hik', 'trek', 'mountain', 'outdoor'])) return Icons.hiking;
  if (has(['photo', 'camera'])) return Icons.photo_camera;
  if (has(['danc'])) return Icons.nightlife;
  if (has(['music', 'sing', 'guitar', 'song'])) return Icons.music_note;
  if (has(['read', 'book', 'writ'])) return Icons.menu_book;
  if (has(['cook', 'food', 'bak'])) return Icons.restaurant;
  if (has(['movie', 'film', 'cinema'])) return Icons.movie;
  if (has(['gym', 'fitness', 'workout', 'sport', 'run'])) return Icons.fitness_center;
  if (has(['art', 'paint', 'draw'])) return Icons.palette;
  if (has(['game', 'gaming'])) return Icons.sports_esports;
  if (has(['yoga', 'medita'])) return Icons.self_improvement;
  if (has(['volunteer', 'charity', 'philanthrop'])) return Icons.volunteer_activism;
  if (has(['tech', 'coding', 'program'])) return Icons.code;
  if (has(['coffee'])) return Icons.local_cafe;
  if (has(['pet', 'dog', 'cat'])) return Icons.pets;
  return Icons.interests;
}

/// Web `buildStarters` fallback when the API sends none.
List<String> _buildStarters(MatchSession m, String otherFirst) {
  const templates = [
    'I saw we both love {i}. What got you into it?',
    "What's the best {i} memory you have?",
    'If we planned a {i} day together, what would it look like?',
  ];
  final out = <String>[
    for (var i = 0; i < m.sharedInterests.length && i < 3; i++)
      templates[i % templates.length].replaceAll('{i}', m.sharedInterests[i].toLowerCase()),
  ];
  if ((m.valuesScore ?? 0) >= 80) out.add("What's one value you'd never compromise on, $otherFirst?");
  if (out.length < 3) out.add('What does a perfect weekend look like for you?');
  return out.take(4).toList();
}

// ---------------------------------------------------------------- body

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({
    required this.match,
    required this.me,
    required this.otherName,
    required this.canUseStarters,
    required this.onUseStarter,
  });

  final MatchSession match;
  final DuoProfile? me;
  final String otherName;
  final bool canUseStarters;
  final ValueChanged<String> onUseStarter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = match;
    final score = (m.compatibilityScore ?? 0).round().clamp(0, 100);
    final verdict = _verdictFor(score);
    final pillars = <({String key, String label, IconData icon, int value, String hint})>[
      (key: 'values', label: 'Core values', icon: Icons.diversity_1, value: (m.valuesScore ?? 0).round(), hint: 'Beliefs, family and priorities'),
      (key: 'lifestyle', label: 'Lifestyle & habits', icon: Icons.self_improvement, value: (m.lifestyleScore ?? 0).round(), hint: 'Daily routine, diet and pace of life'),
      (key: 'career', label: 'Career & ambition', icon: Icons.work_outline, value: (m.careerScore ?? 0).round(), hint: 'Goals, drive and work-life balance'),
      (key: 'hobbies', label: 'Hobbies & leisure', icon: Icons.sports_tennis, value: (m.hobbiesScore ?? 0).round(), hint: 'How you like to spend free time'),
    ];
    final strongest = pillars.reduce((a, b) => b.value > a.value ? b : a);
    final otherFirst = otherName.split(' ').first;
    final starters = m.conversationStarters.isNotEmpty
        ? m.conversationStarters.take(4).toList()
        : _buildStarters(m, otherFirst);
    final summary = (m.insightSummary?.isNotEmpty ?? false)
        ? m.insightSummary!
        : 'You two line up best on ${strongest.label.toLowerCase()} (${strongest.value}%), '
            'with ${m.sharedInterests.length} interests in common.';
    final ago = _matchedAgo(m.matchedAt);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Hero
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(alpha: 0.15),
                scheme.surfaceContainerHigh.withValues(alpha: 0.6),
                const Color(0xFFF59E0B).withValues(alpha: 0.10),
              ],
            ),
          ),
          child: Column(
            children: [
              _ScoreRing(score: score),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Avatar(profile: me),
                  Transform.translate(
                    offset: const Offset(0, 0),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 4),
                      ),
                      child: const Icon(Icons.favorite, size: 16, color: Colors.white),
                    ),
                  ),
                  _Avatar(profile: m.otherUserProfile),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(verdict.icon, color: verdict.color, size: 22),
                  const SizedBox(width: 6),
                  Text(verdict.label,
                      style: TextStyle(color: verdict.color, fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              if (ago != null) ...[
                const SizedBox(height: 4),
                Text(ago, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 10),
              Text(summary,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Card(
          icon: Icons.insights,
          title: 'Compatibility breakdown',
          child: Column(
            children: [
              for (final p in pillars) ...[
                _Pillar(
                  icon: p.icon,
                  label: p.label,
                  hint: p.hint,
                  value: p.value.clamp(0, 100),
                  note: m.pillarNotes[p.key],
                ),
                if (p != pillars.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (m.sparkFactors.isNotEmpty)
          _Card(
            icon: Icons.local_fire_department,
            title: 'What sparks between you',
            child: Column(
              children: [
                for (final f in m.sparkFactors)
                  _Bullet(icon: Icons.star, iconColor: const Color(0xFFFBBF24), text: f),
              ],
            ),
          ),
        if (m.sharedInterests.isNotEmpty)
          _Card(
            icon: Icons.interests,
            title: '${m.sharedInterests.length} shared interest${m.sharedInterests.length == 1 ? '' : 's'}',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in m.sharedInterests)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_interestIcon(i), size: 16, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(i, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if ((m.visionInsight ?? '').isNotEmpty || (m.communicationInsight ?? '').isNotEmpty)
          _Card(
            icon: Icons.psychology_outlined,
            title: 'Deep dive',
            child: Column(
              children: [
                if ((m.visionInsight ?? '').isNotEmpty)
                  _DeepDive(
                    icon: Icons.visibility_outlined,
                    color: scheme.primary,
                    title: 'Vision for the future',
                    body: m.visionInsight!,
                  ),
                if ((m.visionInsight ?? '').isNotEmpty && (m.communicationInsight ?? '').isNotEmpty)
                  const SizedBox(height: 10),
                if ((m.communicationInsight ?? '').isNotEmpty)
                  _DeepDive(
                    icon: Icons.forum_outlined,
                    color: const Color(0xFFF59E0B),
                    title: 'Communication style',
                    body: m.communicationInsight!,
                  ),
              ],
            ),
          ),
        if (m.thingsToTalkAbout.isNotEmpty)
          _Card(
            icon: Icons.forum_outlined,
            title: 'Worth talking about',
            child: Column(
              children: [
                for (final t in m.thingsToTalkAbout)
                  _Bullet(icon: Icons.lightbulb_outline, iconColor: const Color(0xFF38BDF8), text: t),
              ],
            ),
          ),
        if (starters.isNotEmpty)
          _Card(
            icon: Icons.chat_bubble_outline,
            title: 'Conversation starters',
            child: Column(
              children: [
                for (final s in starters)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: scheme.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: canUseStarters ? () => onUseStarter(s) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                              if (canUseStarters) ...[
                                const SizedBox(width: 8),
                                Text('Use',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary)),
                                Icon(Icons.north_east, size: 16, color: scheme.primary),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Text(
            '${m.aiProvider == 'duo' && m.modelSamples != null ? "Overall score from Duo's own model, trained on ${m.modelSamples} real likes, skips and chats. Pillar scores compare both profiles directly." : 'Scores come from both profiles: values, lifestyle, career and interests.'}'
            '${m.aiProvider == 'claude' ? ' The written insights are generated by AI and can be imperfect.' : ''}'
            ' They are a guide, not a verdict.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.5, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- pieces

class _AiBadge extends StatelessWidget {
  const _AiBadge({required this.provider});
  final String? provider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_outlined, size: 15, color: scheme.primary),
          const SizedBox(width: 4),
          Text(provider == 'duo' ? 'Duo AI' : 'AI insights',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.primary)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({required this.icon, required this.label, required this.hint, required this.value, this.note});
  final IconData icon;
  final String label;
  final String hint;
  final int value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: scheme.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$value%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(_levelFor(value).toUpperCase(),
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: scheme.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 8,
              color: scheme.onSurface.withValues(alpha: 0.1),
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value / 100),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, f, __) => FractionallySizedBox(
                  widthFactor: f,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [scheme.primary, const Color(0xFFF59E0B)]),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          if ((note ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(note!, style: TextStyle(fontSize: 12, height: 1.5, color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.iconColor, required this.text});
  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 18, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }
}

class _DeepDive extends StatelessWidget {
  const _DeepDive({required this.icon, required this.color, required this.title, required this.body});
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: scheme.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 14, height: 1.5, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, this.size = 60});
  final DuoProfile? profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = profile == null ? '' : resolveProfilePhotoUrl(profile!);
    final initial = (profile?.displayName.isNotEmpty ?? false) ? profile!.displayName[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHighest,
        border: Border.all(color: scheme.surface, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: url.isEmpty
          ? Center(child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)))
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Center(child: Text(initial)),
            ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 160,
      height: 160,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, p, __) => CustomPaint(
          painter: _RingPainter(progress: p, track: scheme.onSurface.withValues(alpha: 0.1), color: scheme.primary),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$score%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                Text('COMPATIBILITY',
                    style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.track, required this.color});
  final double progress;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [color, const Color(0xFFF59E0B), color],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.track != track || old.color != color;
}

/// Web `AnalysingLoader`: both avatars pulsing while insights are computed.
class _AnalysingLoader extends StatefulWidget {
  const _AnalysingLoader({required this.me, required this.other});
  final DuoProfile? me;
  final DuoProfile? other;

  @override
  State<_AnalysingLoader> createState() => _AnalysingLoaderState();
}

class _AnalysingLoaderState extends State<_AnalysingLoader> with SingleTickerProviderStateMixin {
  static const _steps = [
    'Comparing core values',
    'Matching lifestyles & habits',
    'Weighing career & ambition',
    'Finding shared interests',
  ];
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _step = (_step + 1) % _steps.length);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Avatar(profile: widget.me, size: 56),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.favorite, color: scheme.primary),
                  ),
                  _Avatar(profile: widget.other, size: 56),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('Analysing both profiles', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _steps[_step],
                key: ValueKey(_step),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(width: 160, child: LinearProgressIndicator(borderRadius: BorderRadius.circular(99))),
          ],
        ),
      ),
    );
  }
}

class _MatchPicker extends StatelessWidget {
  const _MatchPicker({required this.matches, required this.selectedId, required this.onSelect});
  final List<MatchSession> matches;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = matches[i];
          final active = m.id == selectedId;
          return ChoiceChip(
            avatar: _Avatar(profile: m.otherUserProfile, size: 24),
            label: Text(m.otherUserProfile.displayName),
            selected: active,
            onSelected: (_) => onSelect(m.id),
            selectedColor: scheme.primary,
            labelStyle: TextStyle(color: active ? scheme.onPrimary : null, fontWeight: FontWeight.w600),
          );
        },
      ),
    );
  }
}
