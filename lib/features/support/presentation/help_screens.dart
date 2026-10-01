import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../data/support_content.dart';

/// Help center hub, mirroring the web `/help` page.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Get Help', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _HelpTile(
                  icon: Icons.quiz_outlined,
                  title: 'FAQ',
                  subtitle: 'Find answers to common questions',
                  onTap: () => context.push(AppRoutes.helpFaq),
                ),
                const Divider(height: 1),
                _HelpTile(
                  icon: Icons.support_agent_outlined,
                  title: 'Contact Support',
                  subtitle: 'Get in touch with our support team',
                  onTap: () => context.push(AppRoutes.helpContact),
                ),
                const Divider(height: 1),
                _HelpTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Report a Bug',
                  subtitle: "Let us know about something that isn't working",
                  onTap: () => context.push(AppRoutes.helpReportBug),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Guides', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < helpGuides.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: Icon(_guideIcons[i % _guideIcons.length], color: theme.colorScheme.primary),
                    title: Text(helpGuides[i].title),
                    subtitle: Text(helpGuides[i].description),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _guideIcons = [
    Icons.favorite_outline,
    Icons.chat_bubble_outline,
    Icons.shield_outlined,
    Icons.payments_outlined,
  ];
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < faqEntries.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ExpansionTile(
                    shape: const Border(),
                    title: Text(
                      faqEntries[i].question,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(faqEntries[i].answer)],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Privacy policy or terms of service, mirroring the web `/legal/*` pages.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(document.updatedLabel,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Text(document.intro, style: theme.textTheme.bodyLarge),
          for (final section in document.sections) ...[
            const SizedBox(height: 24),
            Text(section.heading, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final paragraph in section.body)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(paragraph, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
              ),
          ],
        ],
      ),
    );
  }
}
