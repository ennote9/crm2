// Order Details (Object Page) v1 — sticky header, summary strip, tabs.
// Next step / More driven by available_actions and disabled_actions (mock).
// Ship v1 (demo): updates order status, lines (shipped qty), HU (Shipped), events.

import 'package:flutter/material.dart';

import '../../components/chips/index.dart';
import '../../components/dialogs/index.dart';
import '../../components/progress/index.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import 'order_actions_model.dart';
import 'events_tab.dart';
import 'handling_units_tab.dart';
import 'order_lines_tab.dart';
import 'pick_tasks_tab.dart';
import 'models/order_event.dart';

/// Payload to open order details (from list row).
/// When status is "On Hold", pass [baseStatus] so the chip shows base status (e.g. Allocated) and a separate "On Hold" badge is shown.
class OrderDetailsPayload {
  const OrderDetailsPayload({
    required this.orderNo,
    required this.status,
    required this.warehouse,
    required this.created,
    this.baseStatus,
  });
  final String orderNo;
  final String status;
  final String warehouse;
  final String created;
  /// When status == "On Hold", chip shows this (e.g. "Allocated"); otherwise chip shows status.
  final String? baseStatus;
}

/// Order Details page: sticky header, summary strip, tabs (Lines / Pick Tasks / HU / Events).
class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({
    super.key,
    required this.payload,
  });

  final OrderDetailsPayload payload;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  /// Live order status (initial from payload; updated by Next step).
  late String _orderStatus;
  late List<OrderLineMock> _lines;
  late List<PickTaskMock> _pickTasks;
  late List<HuMock> _hus;
  late List<OrderEventMock> _events;

  /// hasShort from current lines (any line with short > 0).
  bool get _hasShort => _lines.any((l) => l.short > 0);

  bool get _isOnHold => _orderStatus.toLowerCase() == 'on hold';
  bool get _isCancelled => _orderStatus.toLowerCase() == 'cancelled';

  /// Main status for chip: base status when On Hold (no duplicate), else _orderStatus.
  String get _displayStatus {
    if (_isOnHold && widget.payload.baseStatus != null) return widget.payload.baseStatus!;
    return _orderStatus;
  }

  /// Override when Next step is disabled due to On Hold or Cancelled (shown in info icon).
  DisabledActionReason? get _nextDisabledReasonOverride {
    if (_isOnHold) return kReasonHold;
    if (_isCancelled) return kReasonCancelled;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _orderStatus = widget.payload.status;
    _lines = createMockOrderLines();
    final s = widget.payload.status.toLowerCase();
    _pickTasks = (s == 'allocated' || s == 'picking' || s == 'picked' || s == 'packing' || s == 'packed' || s == 'shipped' || s == 'closed')
        ? createPickTasksFromLines(_lines, widget.payload.orderNo)
        : [];
    _hus = createMockHusForOrder(widget.payload.orderNo);
    _events = createMockEventsForOrder(widget.payload.orderNo);
  }

  void _addEvent(String eventCode, [String? note]) {
    _events = List.from(_events)
      ..add(OrderEventMock(
        id: 'EV-$eventCode-${DateTime.now().millisecondsSinceEpoch}',
        eventCode: eventCode,
        occurredAt: DateTime.now().toUtc(),
        actor: 'system',
        note: note,
      ))
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  }

  OrderActionsUi get _actionsUi => createMockOrderActionsUiForStatus(
    _orderStatus,
    hasShort: _hasShort,
    huCount: _hus.length,
  );

  String? get _nextAction =>
      nextAvailableActionByPriority(_actionsUi) ?? nextDisabledActionByPriority(_actionsUi);
  bool get _nextEnabled {
    if (_isOnHold || _isCancelled) return false;
    return _nextAction != null && _actionsUi.availableActions.contains(_nextAction);
  }
  DisabledActionReason? get _nextDisabledReason {
    final override = _nextDisabledReasonOverride;
    if (override != null) return override;
    return _nextAction != null ? _actionsUi.disabledActions[_nextAction] : null;
  }
  ActionReason? get _nextWarning =>
      _nextAction != null ? _actionsUi.actionWarnings[_nextAction] : null;

  Future<void> _onNextStepPressed() async {
    if (!_nextEnabled) return;
    final actionId = _nextAction!;
    final warning = _nextWarning;
    if (warning != null) {
      final confirmed = await showOrderActionReasonDialog(
        context,
        code: warning.code,
        message: warning.message,
      );
      if (!mounted || confirmed != true) return;
    }
    if (!mounted) return;
    if (actionId == 'release') {
      _applyRelease();
      return;
    }
    if (actionId == 'allocate') {
      _applyAllocate();
      return;
    }
    if (actionId == 'start_picking') {
      _applyStartPicking();
      return;
    }
    if (actionId == 'complete_picking') {
      _applyCompletePicking();
      return;
    }
    if (actionId == 'start_packing') {
      _applyStartPacking();
      return;
    }
    if (actionId == 'complete_packing') {
      _applyCompletePacking();
      return;
    }
    if (actionId == 'ship') {
      _applyShip();
      return;
    }
    if (actionId == 'close') {
      _applyClose();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${actionIdToLabel(actionId)} executed (demo)')),
    );
  }

  /// Draft -> Release: status Released, event released.
  void _applyRelease() {
    setState(() {
      _orderStatus = 'Released';
      _addEvent('released', 'Order released to warehouse');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Release executed (demo)')),
      );
    }
  }

  /// Released -> Allocate: status Allocated, event allocated, generate pick tasks if empty.
  void _applyAllocate() {
    setState(() {
      _orderStatus = 'Allocated';
      _addEvent('allocated', 'Full allocation');
      if (_pickTasks.isEmpty) {
        _pickTasks = createPickTasksFromLines(_lines, widget.payload.orderNo);
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allocate executed (demo)')),
      );
    }
  }

  /// Allocated -> Start Picking: status Picking, event pick_started.
  void _applyStartPicking() {
    setState(() {
      _orderStatus = 'Picking';
      _addEvent('pick_started', 'Picking started');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start picking executed (demo)')),
      );
    }
  }

  /// Picking -> Complete Picking: status Picked, event pick_completed, lines picked = reserved or ordered.
  void _applyCompletePicking() {
    setState(() {
      _orderStatus = 'Picked';
      _addEvent('pick_completed', 'Picking completed');
      _lines = _lines.map((line) {
        final qty = line.reserved > 0 ? line.reserved : line.ordered;
        return line.copyWith(picked: qty);
      }).toList();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete picking executed (demo)')),
      );
    }
  }

  /// Picked -> Start Packing: status Packing, event pack_started.
  void _applyStartPacking() {
    setState(() {
      _orderStatus = 'Packing';
      _addEvent('pack_started', 'Packing started');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start packing executed (demo)')),
      );
    }
  }

  /// Packing -> Complete Packing: status Packed, event pack_completed, create HU if empty, lines packed = picked - short or picked.
  void _applyCompletePacking() {
    setState(() {
      _orderStatus = 'Packed';
      _addEvent('pack_completed', 'Packing completed');
      _lines = _lines.map((line) {
        final packedQty = line.short > 0 ? line.picked - line.short : line.picked;
        return line.copyWith(packed: packedQty >= 0 ? packedQty : line.picked);
      }).toList();
      if (_hus.isEmpty) {
        _hus = createDefaultHuFromLines(_lines, widget.payload.orderNo);
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete packing executed (demo)')),
      );
    }
  }

  /// Packed -> Ship: status Shipped, event shipped, HU Shipped, lines shipped_qty.
  void _applyShip() {
    setState(() {
      _orderStatus = 'Shipped';
      _addEvent('shipped', 'Shipment confirmed');
      _hus = _hus.map((h) => h.copyWith(status: 'Shipped')).toList();
      _lines = _lines.map((line) {
        final shippedQty = line.short > 0
            ? line.ordered - line.short
            : line.packed;
        return line.copyWith(shipped: shippedQty);
      }).toList();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ship executed (demo)')),
      );
    }
  }

  /// Shipped -> Close: status Closed, event closed. Next step then shows E_DONE_001.
  void _applyClose() {
    setState(() {
      _orderStatus = 'Closed';
      _addEvent('closed', 'Order closed');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Close executed (demo)')),
      );
    }
  }

  /// Info icon: show disabled reason (E_* including On Hold/Cancelled) or W_* warning; no execution.
  Future<void> _showNextStepReason() async {
    final disabledReason = _nextDisabledReason;
    if (disabledReason != null && mounted) {
      await showOrderActionReasonDialog(
        context,
        code: disabledReason.code,
        message: disabledReason.message,
      );
      return;
    }
    final warning = _nextWarning;
    if (warning != null && mounted) {
      await showOrderActionReasonDialog(
        context,
        code: warning.code,
        message: warning.message,
      );
    }
  }

  Future<void> _onMoreActionSelected(String actionId) async {
    if (_actionsUi.availableActions.contains(actionId)) {
      final warning = _actionsUi.actionWarnings[actionId];
      if (warning != null && mounted) {
        final confirmed = await showOrderActionReasonDialog(
          context,
          code: warning.code,
          message: warning.message,
        );
        if (!mounted || confirmed != true) return;
      }
      if (!mounted) return;
      if (actionId == 'release') {
        _applyRelease();
        return;
      }
      if (actionId == 'allocate') {
        _applyAllocate();
        return;
      }
      if (actionId == 'start_picking') {
        _applyStartPicking();
        return;
      }
      if (actionId == 'complete_picking') {
        _applyCompletePicking();
        return;
      }
      if (actionId == 'start_packing') {
        _applyStartPacking();
        return;
      }
      if (actionId == 'complete_packing') {
        _applyCompletePacking();
        return;
      }
      if (actionId == 'ship') {
        _applyShip();
        return;
      }
      if (actionId == 'close') {
        _applyClose();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${actionIdToLabel(actionId)} executed (demo)')),
      );
      return;
    }
    final reason = _actionsUi.disabledActions[actionId];
    if (reason != null && mounted) {
      await showOrderActionReasonDialog(
        context,
        code: reason.code,
        message: reason.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final density = UiV1DensityTokens.dense;
    final tokens = Theme.of(context).brightness == Brightness.dark
        ? UiV1Tokens.dark
        : UiV1Tokens.light;
    final s = tokens.spacing;
    final nextDisabledReason = _nextDisabledReason;
    final nextWarning = _nextWarning;
    final nextInfoTooltip = nextDisabledReason != null
        ? '${nextDisabledReason.code}: ${nextDisabledReason.message}'
        : (nextWarning != null
            ? '${nextWarning.code}: ${nextWarning.message}'
            : null);
    final showNextStepInfoIcon = nextDisabledReason != null || nextWarning != null;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sticky header
            Material(
              color: colorScheme.surface,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(s.xl, s.md, s.xl, s.sm),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Back',
                        ),
                        SizedBox(width: s.xs),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                widget.payload.orderNo,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              SizedBox(width: s.sm),
                              UiV1StatusChip(
                                label: _displayStatus,
                                variant: UiV1StatusChip.variantFromStatus(_displayStatus),
                              ),
                              if (_isOnHold) ...[
                                SizedBox(width: s.xs),
                                _OrderFlagBadge(label: 'On Hold'),
                              ],
                              if (_hasShort) ...[
                                SizedBox(width: s.xs),
                                _OrderFlagBadge(label: 'Shortage'),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: _nextEnabled
                                  ? (nextWarning != null
                                      ? 'Next step (confirmation required)'
                                      : 'Next step')
                                  : (nextInfoTooltip ?? 'No next action'),
                              child: FilledButton(
                                onPressed: _nextEnabled ? _onNextStepPressed : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: Size(0, density.buttonHeight),
                                ),
                                child: const Text('Next step'),
                              ),
                            ),
                            if (showNextStepInfoIcon) ...[
                              SizedBox(width: s.xxs),
                              IconButton(
                                icon: const Icon(Icons.info_outline, size: 20),
                                onPressed: _showNextStepReason,
                                tooltip: nextInfoTooltip,
                                style: IconButton.styleFrom(
                                  minimumSize: Size(density.buttonHeight, density.buttonHeight),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(width: s.xs),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          tooltip: 'More',
                          onSelected: _onMoreActionSelected,
                          itemBuilder: (context) => kOrderActionIds.map((actionId) {
                            final enabled = _actionsUi.availableActions.contains(actionId);
                            final reason = _actionsUi.disabledActions[actionId];
                            return PopupMenuItem<String>(
                              value: actionId,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  actionIdToLabel(actionId),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: enabled
                                        ? null
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                subtitle: reason != null
                                    ? Text(
                                        reason.message,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.error,
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    // Mini stepper (hidden when Cancelled)
                    if (!_isCancelled) ...[
                      SizedBox(height: s.xs),
                      UiV1OrderStepper(
                        currentStepIndex: orderStatusToStepIndex(_displayStatus),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Summary strip (mock)
            Container(
              padding: EdgeInsets.symmetric(horizontal: s.xl, vertical: s.sm),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SummaryItem(label: 'Ordered', value: '—', theme: theme),
                    SizedBox(width: s.xl),
                    _SummaryItem(label: 'Reserved', value: '—', theme: theme),
                    SizedBox(width: s.xl),
                    _SummaryItem(label: 'Picked', value: '—', theme: theme),
                    SizedBox(width: s.xl),
                    _SummaryItem(label: 'Packed', value: '—', theme: theme),
                    SizedBox(width: s.xl),
                    _SummaryItem(label: 'Shipped', value: '—', theme: theme),
                    SizedBox(width: s.xl),
                    _SummaryItem(label: 'Short', value: '—', theme: theme),
                  ],
                ),
              ),
            ),
            // Tabs
            Material(
              color: colorScheme.surface,
              child: TabBar(
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(text: 'Lines'),
                  Tab(text: 'Pick Tasks'),
                  Tab(text: 'Handling Units'),
                  Tab(text: 'Events'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  OrderLinesTab(
                    orderNo: widget.payload.orderNo,
                    lines: _lines,
                    onLinesChanged: (l) => setState(() => _lines = l),
                  ),
                  PickTasksTab(orderNo: widget.payload.orderNo, tasks: _pickTasks),
                  HandlingUnitsTab(orderNo: widget.payload.orderNo, hus: _hus),
                  EventsTab(orderNo: widget.payload.orderNo, events: _events),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

/// Compact flag badge (On Hold / Shortage only; not for status duplicate).
class _OrderFlagBadge extends StatelessWidget {
  const _OrderFlagBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
