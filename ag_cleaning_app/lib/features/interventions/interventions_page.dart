import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/interventions_repo.dart'; // contient calendarRangeProvider

class InterventionsPage extends ConsumerStatefulWidget {
  const InterventionsPage({super.key});

  @override
  ConsumerState<InterventionsPage> createState() => _InterventionsPageState();
}

class _InterventionsPageState extends ConsumerState<InterventionsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;

  bool _pushedInitial = false;

  @override
  void initState() {
    super.initState();
    // Par défaut: aujourd'hui → aujourd'hui
    final today = DateTime.now();
    _focusedDay = DateTime(today.year, today.month, today.day);
    _rangeStart = _focusedDay;
    _rangeEnd = _focusedDay;
  }

  void _pushRangeToProvider() {
    // IMPORTANT: repousser l'écriture au prochain frame (hors build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final range = (_rangeStart != null && _rangeEnd != null)
          ? DateTimeRange(start: _rangeStart!, end: _rangeEnd!)
          : null;
      ref.read(calendarRangeProvider.notifier).state = range;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pousse la plage initiale une seule fois, après le premier build
    if (!_pushedInitial) {
      _pushedInitial = true;
      _pushRangeToProvider();
    }

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Interventions', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                rangeSelectionMode: _rangeSelectionMode,
                onPageChanged: (fd) => _focusedDay = fd,
                onRangeSelected: (start, end, focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                    _rangeStart = start;
                    _rangeEnd = end ?? start;
                    _rangeSelectionMode = RangeSelectionMode.toggledOn;
                  });
                  _pushRangeToProvider();
                },
                onDaySelected: (selectedDay, focusedDay) {
                  // Sélection jour unique => plage [jour, jour]
                  setState(() {
                    _focusedDay = focusedDay;
                    final d = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                    _rangeStart = d;
                    _rangeEnd = d;
                    _rangeSelectionMode = RangeSelectionMode.toggledOn;
                  });
                  _pushRangeToProvider();
                },
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: scheme.primary.withValues(alpha: 0.18),
                  todayDecoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Ici ta liste/agenda des interventions filtrées par la plage dans calendarRangeProvider
          // Exemple minimal (à brancher sur ton repo plus tard):
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _rangeStart == null
                          ? 'Sélectionne des dates pour afficher les interventions.'
                          : 'Période sélectionnée : '
                            '${_rangeStart!.toString().substring(0, 10)} → ${_rangeEnd!.toString().substring(0, 10)}',
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
