import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stats_models.dart';
import '../models/timer_models.dart';
import '../state/stats_controller.dart';
import '../theme/app_theme.dart';

/// The selectable reporting window for the stats screen.
enum StatsRange {
  today(1, 'Today'),
  week(7, '7 Days'),
  month(30, '30 Days');

  const StatsRange(this.days, this.label);

  final int days;
  final String label;
}

/// Local focus statistics: KPIs, a 7-day chart, and session history.
class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.statsController,
    required this.dailyGoal,
  });

  final StatsController statsController;
  final int dailyGoal;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsRange _range = StatsRange.week;

  Future<void> _exportCsv() async {
    await Clipboard.setData(ClipboardData(text: widget.statsController.toCsv()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied sessions to clipboard')),
    );
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final String date = localizations.formatShortDate(dateTime);
    final String time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$date $time';
  }

  String _phaseLabel(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.pomodoro:
        return 'Pomodoro';
      case TimerPhase.shortBreak:
        return 'Short Break';
      case TimerPhase.longBreak:
        return 'Long Break';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.statsController,
      builder: (BuildContext context, Widget? _) {
        final DateTime now = DateTime.now();
        final int todayCount = widget.statsController.pomodorosOnDate(now);
        final int focusMinutes =
            widget.statsController.focusMinutesInLastDays(_range.days);
        final int pomodoros =
            widget.statsController.pomodorosInLastDays(_range.days);
        final List<MapEntry<DateTime, int>> series =
            widget.statsController.dailyPomodorosSeries(7);
        final List<PomodoroSessionRecord> records =
            widget.statsController.recentRecords;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<StatsRange>(
                      segments: <ButtonSegment<StatsRange>>[
                        for (final StatsRange range in StatsRange.values)
                          ButtonSegment<StatsRange>(
                            value: range,
                            label: Text(range.label),
                          ),
                      ],
                      selected: <StatsRange>{_range},
                      onSelectionChanged: (Set<StatsRange> selection) =>
                          setState(() => _range = selection.first),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: _KpiCard(
                            title: "Today's Goal",
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _kpiValue('$todayCount / ${widget.dailyGoal}'),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: widget.dailyGoal == 0
                                      ? 0
                                      : (todayCount / widget.dailyGoal)
                                          .clamp(0.0, 1.0)
                                          .toDouble(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            title: 'Focus Time',
                            child: _kpiValue(
                              '${focusMinutes ~/ 60}h ${focusMinutes % 60}m',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _KpiCard(
                            title: 'Pomodoros',
                            child: _kpiValue('$pomodoros'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ChartCard(series: series),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const Text(
                        'Recent Sessions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: _exportCsv,
                        child: const Text('Export CSV'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: widget.statsController.clearHistory,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (records.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No completed sessions yet. Finish a Pomodoro to see '
                        'your stats here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    for (final PomodoroSessionRecord record in records)
                      _SessionTile(
                        phaseLabel: _phaseLabel(record.phase),
                        title: record.taskTitle ?? 'Untitled session',
                        category: record.category?.name ?? '—',
                        durationMinutes: record.durationMinutes,
                        timestamp: _formatDateTime(context, record.completedAt),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kpiValue(String value) {
    return Text(
      value,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.series});

  final List<MapEntry<DateTime, int>> series;

  static const List<String> _weekdayLabels = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final int maxCount = series.fold<int>(
      0,
      (int max, MapEntry<DateTime, int> entry) =>
          entry.value > max ? entry.value : max,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Last 7 Days',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (final MapEntry<DateTime, int> entry in series)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: entry.value == 0 || maxCount == 0
                                ? 0
                                : ((entry.value / maxCount) * 72)
                                    .clamp(4.0, 72.0)
                                    .toDouble(),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.brandCrimson,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _weekdayLabels[entry.key.weekday - 1],
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.phaseLabel,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.timestamp,
  });

  final String phaseLabel;
  final String title;
  final String category;
  final int durationMinutes;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '$phaseLabel · $category · $durationMinutes min · $timestamp',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
