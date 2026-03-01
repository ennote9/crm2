// Events tab v1.1: key timestamps panel (chip-like), timeline with line + type markers, group by date. Mock data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/density.dart';
import '../../theme/tokens.dart';
import 'models/order_event.dart';

/// Filter segment: All / Workflow / Exceptions / System
enum EventFilter { all, workflow, exceptions, system }

/// Short labels for key timestamp chips.
String _keyTsLabel(String code) {
  switch (code) {
    case 'pick_started': return 'Pick start';
    case 'pick_completed': return 'Pick done';
    case 'pack_started': return 'Pack start';
    case 'pack_completed': return 'Pack done';
    default: return eventCodeToLabel(code);
  }
}

List<OrderEventMock> _mockEvents(String? orderNo) {
  final seed = (orderNo ?? 'ORD').hashCode & 0x7FFF;
  final base = DateTime.utc(2025, 2, 15, 8, 0);
  final codes = [
    'order_created',
    'released',
    'allocated',
    'pick_started',
    'hold_created',
    'hold_resolved',
    'pick_completed',
    'pack_started',
    'shortage_detected',
    'pack_completed',
    'shipped',
    'export_sent',
    'closed',
    'order_created', // duplicate for count
    'released',
    'allocated',
    'pick_started',
    'pick_completed',
    'pack_started',
    'pack_completed',
  ];
  final actors = [
    'system', 'J.Doe', 'J.Doe', 'M.Smith', 'M.Smith', 'M.Smith', 'M.Smith', 'L.Pack', 'system', 'L.Pack', 'system', 'system', 'J.Doe',
    'system', 'J.Doe', 'J.Doe', 'M.Smith', 'M.Smith', 'L.Pack', 'L.Pack',
  ];
  final notes = [
    'Order created',
    'Order released to warehouse',
    'Full allocation',
    'Picking started',
    'Hold: quality check',
    'Hold released',
    'Picking completed',
    'Packing started',
    'Shortage on line 2',
    'Packing completed',
    'Shipment confirmed',
    'EDI sent',
    'Order closed',
    null, null, null, null, null, null, null,
  ];
  return List.generate(codes.length.clamp(0, 20), (i) {
    final dt = base.add(Duration(hours: i + 1, minutes: (seed % 30) + i * 5));
    return OrderEventMock(
      id: 'EV-$seed-$i',
      eventCode: codes[i],
      occurredAt: dt,
      actor: actors[i % actors.length],
      note: i < notes.length ? notes[i] : null,
    );
  })..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
}

/// Creates mock events for order (used by page state and Events tab).
List<OrderEventMock> createMockEventsForOrder(String? orderNo) => _mockEvents(orderNo);

/// Events tab: key timestamps strip + timeline + filters + search. State preserved when switching tabs.
class EventsTab extends StatefulWidget {
  const EventsTab({super.key, this.orderNo, this.events});

  final String? orderNo;
  /// When provided, tab uses this list (e.g. from page state after Ship).
  final List<OrderEventMock>? events;

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  EventFilter _filter = EventFilter.all;
  final TextEditingController _searchController = TextEditingController();

  late List<OrderEventMock> _allEvents;

  @override
  void initState() {
    super.initState();
    _allEvents = widget.events ?? _mockEvents(widget.orderNo);
  }

  @override
  void didUpdateWidget(EventsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events != null && widget.events != oldWidget.events) {
      _allEvents = List.from(widget.events!)..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Key timestamps: first occurrence of each key code (from sorted-by-time list).
  Map<String, DateTime> get _keyTimestamps {
    final map = <String, DateTime>{};
    for (final e in _allEvents) {
      if (kKeyTimestampCodes.contains(e.eventCode) && !map.containsKey(e.eventCode)) {
        map[e.eventCode] = e.occurredAt;
      }
    }
    return map;
  }

  List<OrderEventMock> get _filteredEvents {
    var list = _allEvents;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((e) =>
        e.eventCode.toLowerCase().contains(query) ||
        e.actor.toLowerCase().contains(query) ||
        (e.note?.toLowerCase().contains(query) ?? false),
      ).toList();
    }
    switch (_filter) {
      case EventFilter.all:
        break;
      case EventFilter.workflow:
        list = list.where((e) => eventCodeToCategory(e.eventCode) == OrderEventCategory.workflow).toList();
        break;
      case EventFilter.exceptions:
        list = list.where((e) => eventCodeToCategory(e.eventCode) == OrderEventCategory.exceptions).toList();
        break;
      case EventFilter.system:
        list = list.where((e) => eventCodeToCategory(e.eventCode) == OrderEventCategory.system).toList();
        break;
    }
    return list;
  }

  /// Flattened timeline entries: date headers + events with first/last in group for line drawing.
  List<_TimelineEntry> get _timelineEntries {
    final events = _filteredEvents;
    if (events.isEmpty) return [];
    final grouped = <String, List<OrderEventMock>>{};
    for (final e in events) {
      final key = '${e.occurredAt.year}-${e.occurredAt.month.toString().padLeft(2, '0')}-${e.occurredAt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final dates = grouped.keys.toList()..sort();
    final entries = <_TimelineEntry>[];
    for (final dateStr in dates) {
      final group = grouped[dateStr]!;
      entries.add(_TimelineEntry(isHeader: true, dateHeader: dateStr));
      for (var i = 0; i < group.length; i++) {
        entries.add(_TimelineEntry(
          event: group[i],
          isFirstInGroup: i == 0,
          isLastInGroup: i == group.length - 1,
        ));
      }
    }
    return entries;
  }

  static String _formatTs(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final keyTs = _keyTimestamps;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{const SingleActivator(LogicalKeyboardKey.escape): _ClearEventSearchIntent()},
      child: Actions(
        actions: {
          _ClearEventSearchIntent: CallbackAction<_ClearEventSearchIntent>(
            onInvoke: (_) {
              _searchController.clear();
              setState(() {});
              return null;
            },
          ),
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(s.xl, s.sm, s.xl, s.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Key timestamps: chip-like cards, all 8 blocks, "—" when missing
              Wrap(
                spacing: s.xs,
                runSpacing: s.xs,
                children: [
                  for (final code in kKeyTimestampCodes)
                    _KeyTsChip(
                      label: _keyTsLabel(code),
                      value: keyTs.containsKey(code) ? _formatTs(keyTs[code]!) : null,
                      theme: theme,
                      s: s,
                    ),
                ],
              ),
              SizedBox(height: s.sm),
              // Filters left, search right (wrap on narrow)
              Wrap(
                spacing: s.sm,
                runSpacing: s.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<EventFilter>(
                    segments: [
                      ButtonSegment<EventFilter>(value: EventFilter.all, label: const Text('All')),
                      ButtonSegment<EventFilter>(value: EventFilter.workflow, label: const Text('Workflow')),
                      ButtonSegment<EventFilter>(value: EventFilter.exceptions, label: const Text('Exceptions')),
                      ButtonSegment<EventFilter>(value: EventFilter.system, label: const Text('System')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (v) => setState(() => _filter = v.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs)),
                      textStyle: WidgetStateProperty.all(theme.textTheme.labelMedium),
                    ),
                  ),
                  SizedBox(width: s.sm),
                  SizedBox(
                    width: 220,
                    height: UiV1DensityTokens.dense.inputHeight,
                    child: ListenableBuilder(
                      listenable: _searchController,
                      builder: (context, _) => TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search eventCode, actor…',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
                          border: const OutlineInputBorder(),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: s.sm),
              // Timeline with vertical line, dots, date groups
              Expanded(
                child: ListView.builder(
                  itemCount: _timelineEntries.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final entry = _timelineEntries[index];
                    if (entry.isHeader) {
                      return _DateHeader(label: entry.dateHeader!, theme: theme, s: s);
                    }
                    return _TimelineRow(
                      event: entry.event!,
                      isFirstInGroup: entry.isFirstInGroup,
                      isLastInGroup: entry.isLastInGroup,
                      theme: theme,
                      s: s,
                      formatTs: _formatTs,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearEventSearchIntent extends Intent {}

/// One entry in the flattened timeline (header or event with group position).
class _TimelineEntry {
  _TimelineEntry({
    this.isHeader = false,
    this.dateHeader,
    this.event,
    this.isFirstInGroup = false,
    this.isLastInGroup = false,
  });
  final bool isHeader;
  final String? dateHeader;
  final OrderEventMock? event;
  final bool isFirstInGroup;
  final bool isLastInGroup;
}

/// Chip-like card for key timestamp: label (small) + time (bold) or "—"; muted when absent.
class _KeyTsChip extends StatelessWidget {
  const _KeyTsChip({required this.label, required this.value, required this.theme, required this.s});
  final String label;
  final String? value;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    final onSurface = theme.colorScheme.onSurface;
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
      decoration: BoxDecoration(
        color: hasValue
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(UiV1RadiusTokens.standard.sm),
        border: Border.all(
          color: hasValue
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: hasValue ? theme.colorScheme.onSurfaceVariant : muted,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            value ?? '—',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: hasValue ? onSurface : muted,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label, required this.theme, required this.s});
  final String label;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  /// Align with event cards (time 88 + xxs + lane 20 + xs)
  static const double _indent = 88 + 4 + 20 + 8;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: s.sm, bottom: s.xxs, left: _indent),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Timeline row: vertical line segment + dot (by type) + compact event card.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.theme,
    required this.s,
    required this.formatTs,
  });
  final OrderEventMock event;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final ThemeData theme;
  final UiV1SpacingTokens s;
  final String Function(DateTime) formatTs;

  static const double _lineWidth = 2;
  static const double _dotSize = 10;
  static const double _laneWidth = 20;

  @override
  Widget build(BuildContext context) {
    final category = eventCodeToCategory(event.eventCode);
    final isException = category == OrderEventCategory.exceptions;
    final isSystem = category == OrderEventCategory.system;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time column (narrow)
          SizedBox(
            width: 88,
            child: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                formatTs(event.occurredAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          SizedBox(width: s.xxs),
          // Vertical line + dot
          SizedBox(
            width: _laneWidth,
            child: Column(
              children: [
                if (!isFirstInGroup) Container(height: 6, width: _lineWidth, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
                Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isException
                        ? theme.colorScheme.error
                        : (isSystem ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5) : theme.colorScheme.primary),
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                ),
                if (!isLastInGroup) Expanded(child: Container(width: _lineWidth, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6))),
                if (isLastInGroup) SizedBox(height: 6),
              ],
            ),
          ),
          SizedBox(width: s.xs),
          // Card + optional badge
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: s.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isException || isSystem)
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isException
                                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.8)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isException ? 'EXCEPTION' : 'SYSTEM',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isException ? theme.colorScheme.onErrorContainer : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(UiV1RadiusTokens.standard.sm),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                eventCodeToLabel(event.eventCode),
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Text(
                              event.actor,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                        if (event.note != null && event.note!.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(
                            event.note!,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
