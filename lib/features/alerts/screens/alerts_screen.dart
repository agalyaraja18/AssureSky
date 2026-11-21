import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/official_alert_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/info_banner.dart';
import '../bloc/alerts_bloc.dart';
import '../widgets/official_alert_card.dart';
import 'alert_detail_screen.dart';

/// Worldwide official weather alerts for today.
///
/// [active] is true while this tab is selected. The (fairly heavy) download
/// only starts the first time the tab is opened, not at app launch.
class AlertsScreen extends StatefulWidget {
  final bool active;
  const AlertsScreen({super.key, this.active = false});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late final AlertsBloc _bloc;
  final TextEditingController _search = TextEditingController();

  bool _started = false;
  OfficialSeverity? _severity; // null = all
  String? _region; // provider id, null = all
  String _query = '';

  @override
  void initState() {
    super.initState();
    _bloc = AlertsBloc();
    _maybeStart();
  }

  @override
  void didUpdateWidget(AlertsScreen old) {
    super.didUpdateWidget(old);
    _maybeStart();
  }

  void _maybeStart() {
    if (widget.active && !_started) {
      _started = true;
      _bloc.add(AlertsLoadRequested());
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _bloc.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    _bloc.add(AlertsLoadRequested(force: true));
    // Keep the pull-to-refresh spinner up until loading has finished.
    await _bloc.stream
        .firstWhere((s) =>
            (s is AlertsLoaded && s.result.isComplete) || s is AlertsError)
        .timeout(const Duration(seconds: 90), onTimeout: () => _bloc.state);
  }

  List<OfficialAlert> _filtered(List<OfficialAlert> all) {
    final q = _query.trim().toLowerCase();
    return all.where((a) {
      if (_severity != null && a.severity != _severity) return false;
      if (_region != null && a.provider != _region) return false;
      if (q.isEmpty) return true;
      return a.title.toLowerCase().contains(q) ||
          a.location.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q) ||
          a.source.toLowerCase().contains(q);
    }).toList();
  }

  void _open(OfficialAlert alert) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AlertDetailScreen(alert: alert),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text('Weather Alerts',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Text(
                  'Official alerts from meteorological & emergency authorities — today, worldwide',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: BlocBuilder<AlertsBloc, AlertsState>(
                  builder: (context, state) => _buildBody(context, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AlertsState state) {
    final theme = Theme.of(context);

    if (state is AlertsInitial || state is AlertsLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 16),
            Text('Contacting weather authorities…',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (state is AlertsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(state.message,
                  textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    _bloc.add(AlertsLoadRequested(force: true)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final result = (state as AlertsLoaded).result;
    final shown = _filtered(result.alerts);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _searchField(theme),
          const SizedBox(height: 10),
          _severityChips(result.alerts),
          const SizedBox(height: 6),
          _regionChips(result.alerts),
          const SizedBox(height: 10),

          // Status banners
          if (result.fromCache) ...[
            OfflineBanner(cachedAt: result.cachedAt),
            const SizedBox(height: 8),
          ],
          if (!result.isComplete) ...[
            _LoadingBanner(pending: result.pendingSources),
            const SizedBox(height: 8),
          ],
          if (result.failedSources.isNotEmpty && result.isComplete) ...[
            InfoBanner(
              icon: Icons.cloud_off,
              text:
                  'Couldn\'t reach: ${result.failedSources.join(', ')}. Showing the other sources.',
            ),
            const SizedBox(height: 8),
          ],

          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 2),
            child: Text(
              '${shown.length} ${shown.length == 1 ? 'alert' : 'alerts'}'
              '${shown.length == result.alerts.length ? '' : ' (of ${result.alerts.length})'}'
              ' · times in your local time',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          if (shown.isEmpty)
            _EmptyState(
              filtered: result.alerts.isNotEmpty,
              stillLoading: !result.isComplete,
            )
          else
            for (final alert in shown)
              OfficialAlertCard(alert: alert, onTap: () => _open(alert)),

          const SizedBox(height: 8),
          _CoverageNote(okSources: result.okSources),
        ],
      ),
    );
  }

  Widget _searchField(ThemeData theme) {
    return TextField(
      controller: _search,
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        hintText: 'Search place, hazard or authority…',
        prefixIcon: const Icon(Icons.search, color: AppColors.accent),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _search.clear();
                  setState(() => _query = '');
                },
              ),
        filled: true,
        fillColor: theme.cardColor,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _severityChips(List<OfficialAlert> all) {
    int count(OfficialSeverity s) => all.where((a) => a.severity == s).length;
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            label: 'All (${all.length})',
            selected: _severity == null,
            onTap: () => setState(() => _severity = null),
          ),
          for (final s in OfficialSeverity.values)
            _chip(
              label: '${s.label} (${count(s)})',
              selected: _severity == s,
              color: AlertStyle.color(s),
              onTap: () => setState(() => _severity = _severity == s ? null : s),
            ),
        ],
      ),
    );
  }

  Widget _regionChips(List<OfficialAlert> all) {
    // Only regions that currently have alerts.
    final providers = <String>[];
    for (final a in all) {
      if (!providers.contains(a.provider)) providers.add(a.provider);
    }
    if (providers.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            label: 'All regions',
            selected: _region == null,
            onTap: () => setState(() => _region = null),
          ),
          for (final p in providers)
            _chip(
              label: AlertStyle.region(p),
              selected: _region == p,
              onTap: () => setState(() => _region = _region == p ? null : p),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color color = AppColors.accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: color.withValues(alpha: 0.22),
        side: BorderSide(color: selected ? color : Colors.transparent),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: selected ? color : null,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _LoadingBanner extends StatelessWidget {
  final List<String> pending;
  const _LoadingBanner({required this.pending});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Still loading: ${pending.join(', ')}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool filtered;
  final bool stillLoading;
  const _EmptyState({required this.filtered, required this.stillLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = stillLoading
        ? 'Nothing yet — more sources are still loading.'
        : filtered
            ? 'No alerts match your filters.'
            : 'No active weather alerts reported by the connected sources right now.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(filtered || stillLoading ? '🔍' : '✅',
              style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(text,
              textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Honest note about where alerts come from and what is not covered.
class _CoverageNote extends StatelessWidget {
  final List<String> okSources;
  const _CoverageNote({required this.okSources});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(
        'Sources: India IMD/NDMA, US National Weather Service, Environment '
        'Canada, MeteoAlarm (Europe) and GDACS (UN/EU global cyclones, floods '
        'and drought). Countries without an open public alert feed — such as '
        'Japan, Australia and China — are not included. For your own safety '
        'always follow your national authority.',
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.4),
      ),
    );
  }
}
