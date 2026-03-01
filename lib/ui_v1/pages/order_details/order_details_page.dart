// Order Details (Object Page) v1 — sticky header, summary strip, tabs.
// Next step / More driven by available_actions and disabled_actions (mock); no business logic.

import 'package:flutter/material.dart';

import '../../components/chips/index.dart';
import '../../components/dialogs/index.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import 'order_actions_model.dart';
import 'order_lines_tab.dart';

/// Payload to open order details (from list row).
class OrderDetailsPayload {
  const OrderDetailsPayload({
    required this.orderNo,
    required this.status,
    required this.warehouse,
    required this.created,
  });
  final String orderNo;
  final String status;
  final String warehouse;
  final String created;
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
  late final OrderActionsUi _actionsUi;

  @override
  void initState() {
    super.initState();
    _actionsUi = createMockOrderActionsUiForStatus(widget.payload.status);
  }

  String? get _nextAction =>
      nextAvailableActionByPriority(_actionsUi) ?? nextDisabledActionByPriority(_actionsUi);
  bool get _nextEnabled =>
      _nextAction != null && _actionsUi.availableActions.contains(_nextAction);
  DisabledActionReason? get _nextDisabledReason =>
      _nextAction != null ? _actionsUi.disabledActions[_nextAction] : null;

  Future<void> _onNextStepPressed() async {
    if (!_nextEnabled) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${actionIdToLabel(_nextAction!)} (placeholder)')),
    );
  }

  Future<void> _showNextStepReason() async {
    final reason = _nextDisabledReason;
    if (reason == null || !mounted) return;
    await showOrderActionReasonDialog(
      context,
      code: reason.code,
      message: reason.message,
    );
  }

  Future<void> _onMoreActionSelected(String actionId) async {
    if (_actionsUi.availableActions.contains(actionId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${actionIdToLabel(actionId)} (placeholder)')),
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
    final nextReason = _nextDisabledReason;
    final nextReasonTooltip = nextReason != null
        ? '${nextReason.code}: ${nextReason.message}'
        : null;

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
                                label: widget.payload.status,
                                variant: UiV1StatusChip.variantFromStatus(widget.payload.status),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: _nextEnabled
                                  ? 'Next step'
                                  : (nextReasonTooltip ?? 'No next action'),
                              child: FilledButton(
                                onPressed: _nextEnabled ? _onNextStepPressed : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: Size(0, density.buttonHeight),
                                ),
                                child: const Text('Next step'),
                              ),
                            ),
                            if (nextReason != null) ...[
                              SizedBox(width: s.xxs),
                              IconButton(
                                icon: const Icon(Icons.info_outline, size: 20),
                                onPressed: _showNextStepReason,
                                tooltip: nextReasonTooltip,
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
                  OrderLinesTab(orderNo: widget.payload.orderNo),
                  _TabStub(
                    title: 'Pick Tasks',
                    mockLines: ['Pick task A', 'Pick task B'],
                  ),
                  _TabStub(
                    title: 'Handling Units',
                    mockLines: ['HU 1', 'HU 2'],
                  ),
                  _TabStub(
                    title: 'Events',
                    mockLines: ['Event 1', 'Event 2', 'Event 3'],
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

class _TabStub extends StatelessWidget {
  const _TabStub({
    required this.title,
    required this.mockLines,
  });

  final String title;
  final List<String> mockLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = UiV1SpacingTokens.standard;
    return ListView(
      padding: EdgeInsets.all(s.xl),
      children: [
        Text(
          '$title — placeholder',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: s.sm),
        ...mockLines.map((line) => Padding(
          padding: EdgeInsets.only(bottom: s.xs),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(line, overflow: TextOverflow.ellipsis, maxLines: 1),
            tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UiV1RadiusTokens.standard.md),
            ),
          ),
        )),
      ],
    );
  }
}
