import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/security_providers.dart';

class LoginHistoryScreen extends ConsumerStatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  ConsumerState<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends ConsumerState<LoginHistoryScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  bool? _successFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = LoginHistoryQuery(search: _search, successFilter: _successFilter);
    final history = ref.watch(loginHistoryProvider(query));

    return Scaffold(
      appBar: AppBar(title: const Text('Login History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search device, location, IP…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => setState(() => _search = v.trim()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _successFilter == null,
                  onSelected: (_) => setState(() => _successFilter = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Success'),
                  selected: _successFilter == true,
                  onSelected: (_) => setState(() => _successFilter = true),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Failed'),
                  selected: _successFilter == false,
                  onSelected: (_) => setState(() => _successFilter = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (page) {
                if (page.results.isEmpty) {
                  return const Center(child: Text('No login activity found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: page.results.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final entry = page.results[index];
                    final scheme = Theme.of(context).colorScheme;
                    final time = entry.createdAt != null
                        ? DateFormat('MMM d, y · HH:mm').format(entry.createdAt!.toLocal())
                        : 'Unknown time';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: entry.success
                            ? scheme.primary.withValues(alpha: 0.12)
                            : scheme.error.withValues(alpha: 0.12),
                        child: Icon(
                          entry.success ? Icons.login_rounded : Icons.block_rounded,
                          color: entry.success ? scheme.primary : scheme.error,
                        ),
                      ),
                      title: Text(entry.deviceName.isNotEmpty ? entry.deviceName : 'Unknown device'),
                      subtitle: Text(
                        [
                          time,
                          if (entry.location.isNotEmpty) entry.location,
                          if (entry.ipAddress != null) entry.ipAddress!,
                        ].join(' · '),
                      ),
                      trailing: entry.isCurrent
                          ? Chip(
                              label: const Text('Current'),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
