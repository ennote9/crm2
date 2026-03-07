// Movement Details (Object Page) v1 — header, sections, actions, events.
// Polished to match Order Details / Product Details quality.

import 'package:flutter/material.dart';

import '../../components/chips/index.dart';
import '../../components/icon_widget.dart';
import '../../components/section_card.dart';
import '../../demo_data/demo_data.dart';
import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import '../products/sku_link_text.dart';

/// Payload to open movement details.
class MovementDetailsPayload {
  const MovementDetailsPayload({required this.movementId});
  final String movementId;
}

/// Movement details: header (no, status, type, next step, more), sections, events timeline.
class MovementDetailsPage extends StatefulWidget {
  const MovementDetailsPage({super.key, required this.payload});

  final MovementDetailsPayload payload;

  @override
  State<MovementDetailsPage> createState() => _MovementDetailsPageState();
}

class _MovementDetailsPageState extends State<MovementDetailsPage> {
  DemoMovement? _movement;
  List<DemoEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _refreshFromRepo();
  }

  void _refreshFromRepo() {
    final m = demoRepository.getMovementById(widget.payload.movementId);
    final events = m != null ? demoRepository.getMovementEvents(m.id) : <DemoEvent>[];
    setState(() {
      _movement = m;
      _events = events;
    });
  }

  String? _getNextAction() {
    final m = _movement;
    if (m == null) return null;
    switch (m.status) {
      case 'Draft':
        return 'release';
      case 'Released':
        return 'start';
      case 'In Progress':
        return 'complete';
      default:
        return null;
    }
  }

  String _getNextActionLabel() {
    switch (_getNextAction()) {
      case 'release':
        return 'Release';
      case 'start':
        return 'Start movement';
      case 'complete':
        return 'Complete movement';
      default:
        return 'Next step';
    }
  }

  void _onNextStepPressed() {
    final action = _getNextAction();
    if (action == null || _movement == null) return;
    final err = demoRepository.applyMovementAction(_movement!.id, action, 'Demo User');
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _refreshFromRepo();
  }

  void _onMoreActionSelected(String actionId) {
    if (actionId == 'cancel' && _movement != null) {
      final err = demoRepository.applyMovementAction(_movement!.id, 'cancel', 'Demo User');
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
      _refreshFromRepo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final density = UiV1DensityTokens.dense;

    if (_movement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Movement')),
        body: const Center(child: Text('Movement not found')),
      );
    }

    final m = _movement!;
    final nextAction = _getNextAction();
    final canCancel = ['Draft', 'Released', 'In Progress'].contains(m.status);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header — denser, aligned with Order Details
          Material(
            color: colorScheme.surface,
            elevation: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(s.lg, s.sm, s.lg, s.xs),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: tokens.colors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const UiV1Icon(icon: UiIcons.arrowBack),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                    style: IconButton.styleFrom(
                      minimumSize: Size(density.buttonHeight, density.buttonHeight),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(width: s.xxs),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.movementNo,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: s.sm),
                        UiV1StatusChip(
                          label: m.status,
                          variant: _statusVariant(m.status),
                        ),
                        SizedBox(width: s.xxs),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(tokens.radius.sm),
                          ),
                          child: Text(m.movementType.label, style: theme.textTheme.labelMedium),
                        ),
                      ],
                    ),
                  ),
                  if (nextAction != null) ...[
                    FilledButton.icon(
                      onPressed: _onNextStepPressed,
                      style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
                      icon: const UiV1Icon(icon: UiIcons.arrowForward, size: 20),
                      label: Text(_getNextActionLabel()),
                    ),
                    SizedBox(width: s.xxs),
                  ],
                  PopupMenuButton<String>(
                    icon: const UiV1Icon(icon: UiIcons.moreHoriz),
                    tooltip: 'More',
                    onSelected: _onMoreActionSelected,
                    itemBuilder: (context) => [
                      if (canCancel)
                        const PopupMenuItem<String>(
                          value: 'cancel',
                          child: ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text('Cancel movement')),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(s.xl, s.sm, s.xl, s.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UiV1SectionCard(
                    title: 'Summary',
                    child: _SummaryCompact(movement: m, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Product / SKU',
                    child: _ProductBlock(movement: m, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Source / Destination',
                    child: _SourceDestinationBlock(movement: m, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Quantity',
                    child: _QuantityBlock(movement: m, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Stock impact',
                    child: _StockImpactBlock(movement: m, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Events',
                    child: _MovementEventsTimeline(events: _events, theme: theme, s: s),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static UiV1StatusVariant _statusVariant(String status) {
    final s = status.toLowerCase();
    if (s == 'draft') return UiV1StatusVariant.neutral;
    if (s == 'released') return UiV1StatusVariant.info;
    if (s == 'in progress') return UiV1StatusVariant.inProgress;
    if (s == 'completed') return UiV1StatusVariant.success;
    if (s == 'cancelled') return UiV1StatusVariant.warning;
    return UiV1StatusVariant.neutral;
  }
}

/// Compact two-column summary: label width fixed, minimal vertical gap.
class _SummaryCompact extends StatelessWidget {
  const _SummaryCompact({required this.movement, required this.theme, required this.s});
  final DemoMovement movement;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    const labelWidth = 72.0;
    final rows = <Widget>[
      _row('Movement No', movement.movementNo, labelWidth),
      _row('Warehouse', movement.warehouse, labelWidth),
      _row('Type', movement.movementType.label, labelWidth),
      _row('Status', movement.status, labelWidth),
      _row('Created', movement.createdAt, labelWidth),
      if (movement.releasedAt != null) _row('Released', movement.releasedAt!, labelWidth),
      if (movement.startedAt != null) _row('Started', movement.startedAt!, labelWidth),
      if (movement.completedAt != null) _row('Completed', movement.completedAt!, labelWidth),
      if (movement.cancelledAt != null) _row('Cancelled', movement.cancelledAt!, labelWidth),
      if (movement.actor != null) _row('Actor', movement.actor!, labelWidth),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows.asMap().entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(bottom: e.key < rows.length - 1 ? s.xxs : 0),
          child: e.value,
        );
      }).toList(),
    );
  }

  Widget _row(String label, String value, double labelWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

/// Product / SKU: SKU and product name link to Product Details; optional lot/expiry.
class _ProductBlock extends StatelessWidget {
  const _ProductBlock({required this.movement, required this.theme, required this.s});
  final DemoMovement movement;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SkuLinkText(sku: movement.sku),
            SizedBox(width: s.sm),
            Expanded(
              child: SkuLinkText(
                sku: movement.sku,
                label: movement.productName,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
              ),
            ),
          ],
        ),
        if (movement.lot != null || movement.expiryDate != null) ...[
          SizedBox(height: s.xxs),
          Wrap(
            spacing: s.sm,
            runSpacing: s.xxs,
            children: [
              if (movement.lot != null)
                Text('Lot: ${movement.lot}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (movement.expiryDate != null)
                Text('Expiry: ${movement.expiryDate}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Source / Destination: from → to with warehouse; clear movement context.
class _SourceDestinationBlock extends StatelessWidget {
  const _SourceDestinationBlock({required this.movement, required this.theme, required this.s});
  final DemoMovement movement;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          movement.warehouse,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: s.xxs),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(UiV1RadiusTokens.standard.sm),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('From', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(movement.fromLocation, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: s.xs),
              child: UiV1Icon(icon: UiIcons.arrowForward, size: 20, color: theme.colorScheme.onSurfaceVariant),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(UiV1RadiusTokens.standard.sm),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('To', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(movement.toLocation, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Quantity: Requested, Moved, Remaining (when not Completed).
class _QuantityBlock extends StatelessWidget {
  const _QuantityBlock({required this.movement, required this.theme, required this.s});
  final DemoMovement movement;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    final remaining = movement.status != 'Completed' ? (movement.qty - movement.movedQty).clamp(0, movement.qty) : 0;
    return Row(
      children: [
        _qtyChip(theme, 'Requested', movement.qty),
        SizedBox(width: s.sm),
        _qtyChip(theme, 'Moved', movement.movedQty),
        if (movement.status != 'Completed' && remaining > 0) ...[
          SizedBox(width: s.sm),
          _qtyChip(theme, 'Remaining', remaining),
        ],
      ],
    );
  }

  Widget _qtyChip(ThemeData theme, String label, int value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(UiV1RadiusTokens.standard.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          SizedBox(width: s.xxs),
          Text('$value', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Stock impact: current available at source and destination (read-only from repo).
class _StockImpactBlock extends StatelessWidget {
  const _StockImpactBlock({required this.movement, required this.theme, required this.s});
  final DemoMovement movement;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    final inv = demoRepository.getInventoryBySku(movement.sku);
    final fromAvailable = inv
        .where((r) => r.warehouse == movement.warehouse && r.location == movement.fromLocation)
        .fold<int>(0, (sum, r) => sum + r.availableQty);
    final toAvailable = inv
        .where((r) => r.warehouse == movement.warehouse && r.location == movement.toLocation)
        .fold<int>(0, (sum, r) => sum + r.availableQty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(movement.fromLocation, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Text('$fromAvailable available', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Movement', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text('${movement.qty}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(movement.toLocation, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Text('$toAvailable available', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Events in timeline style: time column, lane with dot + line, card (same language as order events_tab).
class _MovementEventsTimeline extends StatelessWidget {
  const _MovementEventsTimeline({required this.events, required this.theme, required this.s});
  final List<DemoEvent> events;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  static String _formatTs(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _eventCodeToLabel(String code) {
    const map = {
      'movement_created': 'Created',
      'movement_released': 'Released',
      'movement_started': 'Started',
      'movement_completed': 'Completed',
      'movement_cancelled': 'Cancelled',
    };
    return map[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Text('No events', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final r = UiV1RadiusTokens.standard;
    const laneWidth = 20.0;
    const dotSize = 10.0;
    const lineWidth = 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < events.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    _formatTs(events[i].occurredAt),
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
              SizedBox(
                width: laneWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                        border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                      ),
                    ),
                    if (i < events.length - 1)
                      SizedBox(
                        height: 20,
                        child: Center(
                          child: Container(
                            width: lineWidth,
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    else
                      SizedBox(height: 6),
                  ],
                ),
              ),
              SizedBox(width: s.xs),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: s.xs),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xxs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(r.md),
                      border: Border.all(color: tokens.colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _eventCodeToLabel(events[i].code),
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Text(
                              events[i].actor,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                        if (events[i].payload != null && events[i].payload!.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(
                            events[i].payload!,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
