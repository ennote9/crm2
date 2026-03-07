// Order Details (Object Page) v1 — sticky header, summary strip, tabs.
// Next step / More driven by available_actions and disabled_actions (mock).
// Ship v1 (demo): updates order status, lines (shipped qty), HU (Shipped), events.

import 'package:flutter/material.dart';

import '../../components/chips/index.dart';
import '../../components/dialogs/index.dart';
import '../../components/icon_widget.dart';
import '../../components/progress/index.dart';
import '../../demo_data/demo_data.dart';
import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import 'document_preview_dialog.dart';
import 'order_actions_model.dart';
import 'events_tab.dart';
import 'handling_units_tab.dart';
import 'order_lines_tab.dart';
import 'pick_tasks_tab.dart';

/// Payload to open order details (from list row).
/// When status is "On Hold", pass [baseStatus] so the chip shows base status (e.g. Allocated) and a separate "On Hold" badge is shown.
class OrderDetailsPayload {
  const OrderDetailsPayload({
    required this.orderNo,
    required this.status,
    required this.warehouse,
    required this.created,
    this.baseStatus,
    this.initialTabIndex,
  });
  final String orderNo;
  final String status;
  final String warehouse;
  final String created;
  /// When status == "On Hold", chip shows this (e.g. "Allocated"); otherwise chip shows status.
  final String? baseStatus;
  /// Tab to select when opening (0=Lines, 1=Pick Tasks, 2=HU, 3=Events). Default 0.
  final int? initialTabIndex;
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
  late String _orderStatus;
  late List<DemoOrderLine> _lines;
  late List<DemoPickTask> _pickTasks;
  late List<DemoHandlingUnit> _hus;
  late List<DemoEvent> _events;

  bool get _hasShort => _lines.any((l) => l.shortQty > 0);

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
    _refreshFromRepo();
  }

  void _refreshFromRepo() {
    final bundle = demoRepository.getOrderDetails(widget.payload.orderNo);
    setState(() {
      _orderStatus = bundle.order.status;
      _lines = bundle.lines;
      _pickTasks = bundle.tasks;
      _hus = bundle.hus;
      _events = bundle.events;
    });
  }

  OrderActionsUi get _actionsUi => createMockOrderActionsUiForStatus(
    _orderStatus,
    hasShort: _hasShort,
    huCount: _hus.length,
  );

  void _applyAction(String actionId) {
    final orderNo = widget.payload.orderNo;
    if (actionId == 'place_on_hold' || actionId == 'resolve_hold') {
      if (!canExecuteHoldAction()) {
        if (mounted) _showPermissionDenied();
        return;
      }
    } else if (!canExecuteOrderAction(actionId)) {
      if (mounted) _showPermissionDenied();
      return;
    }
    bool ok = false;
    if (actionId == 'place_on_hold') {
      ok = outboundWorkflowEngine.placeOnHold(orderNo);
    } else if (actionId == 'resolve_hold') {
      ok = outboundWorkflowEngine.resolveHold(orderNo);
    } else {
      ok = outboundWorkflowEngine.executeOrderAction(orderNo, actionId);
    }
    _refreshFromRepo();
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${actionIdToLabel(actionId)} executed')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action not allowed in current state')),
        );
      }
    }
  }

  void _showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Недостаточно прав для выполнения действия.')),
    );
  }

  String? get _nextAction =>
      nextAvailableActionByPriority(_actionsUi) ?? nextDisabledActionByPriority(_actionsUi);
  bool get _nextEnabled {
    if (_isOnHold || _isCancelled) return false;
    final action = _nextAction;
    if (action == null || !_actionsUi.availableActions.contains(action)) return false;
    if (!canExecuteOrderAction(action)) return false;
    if (action == 'allocate' && !_hasAnyAvailableStock) return false;
    return true;
  }
  DisabledActionReason? get _nextDisabledReason {
    final override = _nextDisabledReasonOverride;
    if (override != null) return override;
    final action = _nextAction;
    if (action != null && isPermissionDeniedForOrderAction(action)) {
      return const DisabledActionReason(code: kPermissionDeniedCode, message: kPermissionDeniedMessage);
    }
    if (action == 'allocate' && !_hasAnyAvailableStock) {
      return const DisabledActionReason(code: 'E_INV_001', message: 'Нет доступного остатка для резервирования.');
    }
    return action != null ? _actionsUi.disabledActions[action] : null;
  }
  bool get _hasAnyAvailableStock {
    final wh = widget.payload.warehouse;
    for (final l in _lines) {
      if (demoRepository.getAvailableQty(wh, l.sku) > 0) return true;
    }
    return false;
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
    _applyAction(actionId);
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
      _applyAction(actionId);
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

  bool get _canShowShipmentPreview {
    final s = _orderStatus.toLowerCase();
    return s == 'packed' || s == 'shipped' || s == 'closed';
  }

  void _onDocumentSelected(String docId) {
    final orderNo = widget.payload.orderNo;
    try {
      if (docId == 'packing_slip') {
        final preview = demoRepository.buildPackingSlipPreview(orderNo);
        showPackingSlipPreviewDialog(context, preview: preview);
      } else if (docId == 'shipment_summary' && _canShowShipmentPreview) {
        final preview = demoRepository.buildShipmentPreview(orderNo);
        showShipmentPreviewDialog(context, preview: preview);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to load preview.')));
      }
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
      initialIndex: (widget.payload.initialTabIndex ?? 0).clamp(0, 3),
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
                    bottom: BorderSide(color: tokens.colors.border),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const UiV1Icon(icon: UiIcons.arrowBack),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Back',
                        ),
                        SizedBox(width: s.xs),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.payload.orderNo,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
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
                              child: FilledButton.icon(
                                onPressed: _nextEnabled ? _onNextStepPressed : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: Size(0, density.buttonHeight),
                                ),
                                icon: const UiV1Icon(icon: UiIcons.arrowForward, size: 20),
                                label: const Text('Next step'),
                              ),
                            ),
                            if (showNextStepInfoIcon) ...[
                              SizedBox(width: s.xxs),
                              IconButton(
                                icon: const UiV1Icon(icon: UiIcons.info, size: 20),
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
                          icon: const UiV1Icon(icon: UiIcons.orders),
                          tooltip: 'Documents',
                          onSelected: _onDocumentSelected,
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'packing_slip',
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text('Packing slip'),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'shipment_summary',
                              enabled: _canShowShipmentPreview,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Shipment summary',
                                  style: _canShowShipmentPreview
                                      ? null
                                      : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                subtitle: _canShowShipmentPreview
                                    ? null
                                    : Text(
                                        'Available when order is Packed / Shipped / Closed',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          icon: const UiV1Icon(icon: UiIcons.moreHoriz),
                          tooltip: 'More',
                          onSelected: _onMoreActionSelected,
                          itemBuilder: (context) => kOrderActionIds.map((actionId) {
                            final workflowEnabled = _actionsUi.availableActions.contains(actionId);
                            final hasPermission = canExecuteOrderAction(actionId);
                            final enabled = workflowEnabled && hasPermission;
                            final reason = !hasPermission
                                ? const DisabledActionReason(code: kPermissionDeniedCode, message: kPermissionDeniedMessage)
                                : _actionsUi.disabledActions[actionId];
                            return PopupMenuItem<String>(
                              value: actionId,
                              enabled: enabled,
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
            // Summary strip (from lines / inventory)
            Builder(
              builder: (context) {
                final ordered = _lines.fold<int>(0, (s, l) => s + l.orderedQty);
                final reserved = _lines.fold<int>(0, (s, l) => s + l.reservedQty);
                final picked = _lines.fold<int>(0, (s, l) => s + l.pickedQty);
                final packed = _lines.fold<int>(0, (s, l) => s + l.packedQty);
                final shipped = _lines.fold<int>(0, (s, l) => s + l.shippedQty);
                final short = _lines.fold<int>(0, (s, l) => s + l.shortQty);
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: s.xl, vertical: s.sm),
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SummaryItem(label: 'Ordered', value: '$ordered', theme: theme),
                        SizedBox(width: s.xl),
                        _SummaryItem(label: 'Reserved', value: '$reserved', theme: theme),
                        SizedBox(width: s.xl),
                        _SummaryItem(label: 'Picked', value: '$picked', theme: theme),
                        SizedBox(width: s.xl),
                        _SummaryItem(label: 'Packed', value: '$packed', theme: theme),
                        SizedBox(width: s.xl),
                        _SummaryItem(label: 'Shipped', value: '$shipped', theme: theme),
                        SizedBox(width: s.xl),
                        _SummaryItem(label: 'Short', value: '$short', theme: theme),
                      ],
                    ),
                  ),
                );
              },
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
                    onLinesChanged: (l) {
                      demoRepository.setOrderLines(widget.payload.orderNo, l);
                      _refreshFromRepo();
                    },
                    onOrderDataChanged: _refreshFromRepo,
                  ),
                  PickTasksTab(
                    orderNo: widget.payload.orderNo,
                    tasks: _pickTasks,
                    onOrderDataChanged: _refreshFromRepo,
                  ),
                  HandlingUnitsTab(
                    orderNo: widget.payload.orderNo,
                    hus: _hus,
                    onOrderDataChanged: _refreshFromRepo,
                  ),
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
