// Count Task Details (Object Page) v1 — summary, product, location, quantity, variance, reason, events, actions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/chips/index.dart';
import '../../components/icon_widget.dart';
import '../../components/section_card.dart';
import '../../demo_data/demo_data.dart';
import '../../icons/ui_icons.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';
import '../products/product_details_page.dart';
import '../products/sku_link_text.dart';

/// Payload to open count task details.
class CountTaskDetailsPayload {
  const CountTaskDetailsPayload({required this.taskId});
  final String taskId;
}

/// Count task details: header (countNo, status), sections, actions (Release, Mark counted, Post, Cancel), events.
class CountTaskDetailsPage extends StatefulWidget {
  const CountTaskDetailsPage({super.key, required this.payload});

  final CountTaskDetailsPayload payload;

  @override
  State<CountTaskDetailsPage> createState() => _CountTaskDetailsPageState();
}

class _CountTaskDetailsPageState extends State<CountTaskDetailsPage> {
  DemoCountTask? _task;
  List<DemoEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _refreshFromRepo();
  }

  void _refreshFromRepo() {
    final t = demoRepository.getCountTaskById(widget.payload.taskId);
    final events = t != null ? demoRepository.getCountTaskEvents(t.id) : <DemoEvent>[];
    setState(() {
      _task = t;
      _events = events;
    });
  }

  static UiV1StatusVariant _statusVariant(String status) {
    switch (status) {
      case 'Draft':
        return UiV1StatusVariant.neutral;
      case 'Released':
        return UiV1StatusVariant.info;
      case 'Counted':
        return UiV1StatusVariant.warning;
      case 'Posted':
        return UiV1StatusVariant.success;
      case 'Cancelled':
        return UiV1StatusVariant.danger;
      default:
        return UiV1StatusVariant.neutral;
    }
  }

  void _onRelease() {
    if (_task == null || _task!.status != 'Draft') return;
    final err = demoRepository.applyCountAction(_task!.id, 'release', actor: 'Demo User');
    if (err != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _refreshFromRepo();
  }

  void _onMarkCounted() {
    if (_task == null || _task!.status != 'Released') return;
    _showMarkCountedDialog();
  }

  void _showMarkCountedDialog() {
    final task = _task!;
    final countedController = TextEditingController(text: '${task.expectedQty}');
    final reasonController = TextEditingController(text: task.reasonCode ?? '');

    void submit() {
      final cq = int.tryParse(countedController.text);
      if (cq == null || cq < 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Counted qty must be a non-negative number')));
        return;
      }
      final reason = reasonController.text.trim();
      final variance = cq - task.expectedQty;
      if (variance != 0 && reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reason code required when variance is not zero')));
        return;
      }
      final err = demoRepository.applyCountAction(task.id, 'count', countedQty: cq, reasonCode: reason.isEmpty ? null : reason, actor: 'Demo User');
      Navigator.of(context).pop();
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      } else {
        _refreshFromRepo();
      }
    }

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final s = Theme.of(ctx).brightness == Brightness.dark ? UiV1Tokens.dark.spacing : UiV1Tokens.light.spacing;
        return AlertDialog(
          title: const Text('Mark counted'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              final cq = int.tryParse(countedController.text);
              final variance = (cq ?? task.expectedQty) - task.expectedQty;
              final needReason = variance != 0;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Expected: ${task.expectedQty}', style: theme.textTheme.bodyMedium),
                    SizedBox(height: s.sm),
                    TextField(
                      controller: countedController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Counted qty',
                        hintText: 'Enter counted quantity',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    if (needReason) ...[
                      SizedBox(height: s.sm),
                      TextField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason code (required when variance ≠ 0)',
                          hintText: 'e.g. ADJ, DAMAGE',
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: submit, child: const Text('Save')),
          ],
        );
      },
    ).then((_) {
      countedController.dispose();
      reasonController.dispose();
    });
  }

  void _onPostAdjustment() {
    if (_task == null || _task!.status != 'Counted') return;
    final t = _task!;
    if (t.countedQty == null) return;
    final variance = t.varianceQty;
    if (variance != 0 && (t.reasonCode == null || t.reasonCode!.trim().isEmpty)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reason code required when variance is not zero')));
      return;
    }
    final err = demoRepository.applyCountAction(t.id, 'post', actor: 'Demo User');
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _refreshFromRepo();
  }

  void _onCancel() {
    if (_task == null || !['Draft', 'Released', 'Counted'].contains(_task!.status)) return;
    final err = demoRepository.applyCountAction(_task!.id, 'cancel', actor: 'Demo User');
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _refreshFromRepo();
  }

  void _openProduct() {
    if (_task == null) return;
    final p = demoRepository.getProductBySku(_task!.sku);
    if (p != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailsPage(payload: ProductDetailsPayload(productId: p.productId, sku: p.sku)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    final s = tokens.spacing;
    final density = UiV1DensityTokens.dense;

    if (_task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Count task')),
        body: const Center(child: Text('Count task not found')),
      );
    }

    final t = _task!;
    final canRelease = t.status == 'Draft';
    final canMarkCounted = t.status == 'Released';
    final canPost = t.status == 'Counted' && (t.varianceQty == 0 || (t.reasonCode != null && t.reasonCode!.trim().isNotEmpty));
    final canCancel = ['Draft', 'Released', 'Counted'].contains(t.status);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                            t.countNo,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: s.sm),
                        UiV1StatusChip(label: t.status, variant: _statusVariant(t.status)),
                      ],
                    ),
                  ),
                  if (canRelease)
                    FilledButton(
                      onPressed: _onRelease,
                      style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
                      child: const Text('Release'),
                    ),
                  if (canMarkCounted) ...[
                    if (canRelease) SizedBox(width: s.xxs),
                    FilledButton(
                      onPressed: _onMarkCounted,
                      style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
                      child: const Text('Mark counted'),
                    ),
                  ],
                  if (canPost) ...[
                    if (canRelease || canMarkCounted) SizedBox(width: s.xxs),
                    FilledButton(
                      onPressed: _onPostAdjustment,
                      style: FilledButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
                      child: const Text('Post adjustment'),
                    ),
                  ],
                  if (canCancel) ...[
                    SizedBox(width: s.xxs),
                    OutlinedButton(
                      onPressed: _onCancel,
                      style: OutlinedButton.styleFrom(minimumSize: Size(0, density.buttonHeight)),
                      child: const Text('Cancel'),
                    ),
                  ],
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
                    child: _SummaryBlock(task: t, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Product / SKU',
                    child: _ProductBlock(task: t, theme: theme, s: s, onTap: _openProduct),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Location',
                    child: _LocationBlock(task: t, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Quantity',
                    child: _QuantityBlock(task: t, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Variance',
                    child: _VarianceBlock(task: t, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Reason / Adjustment',
                    child: _ReasonBlock(task: t, theme: theme, s: s),
                  ),
                  SizedBox(height: s.sm),
                  UiV1SectionCard(
                    title: 'Events',
                    child: _CountTaskEventsTimeline(events: _events, theme: theme, s: s),
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

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.task, required this.theme, required this.s});
  final DemoCountTask task;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Count No', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            SizedBox(width: s.xs),
            Text(task.countNo, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        if (task.actor != null) ...[
          SizedBox(height: s.xxs),
          Row(
            children: [
              Text('Actor', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              SizedBox(width: s.xs),
              Text(task.actor!, style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
        Row(
          children: [
            Text('Created', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            SizedBox(width: s.xs),
            Text(task.createdAt, style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

class _ProductBlock extends StatelessWidget {
  const _ProductBlock({required this.task, required this.theme, required this.s, required this.onTap});
  final DemoCountTask task;
  final ThemeData theme;
  final UiV1SpacingTokens s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UiV1RadiusTokens.standard.sm),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: s.xxs),
        child: Row(
          children: [
            SkuLinkText(sku: task.sku),
            SizedBox(width: s.sm),
            Expanded(
              child: Text(
                task.productName,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            UiV1Icon(icon: UiIcons.chevronRight, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.task, required this.theme, required this.s});
  final DemoCountTask task;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(task.warehouse, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            SizedBox(width: s.xs),
            Text(task.location, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        if (task.lot != null && task.lot!.isNotEmpty) ...[
          SizedBox(height: s.xxs),
          Text('Lot: ${task.lot}', style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _QuantityBlock extends StatelessWidget {
  const _QuantityBlock({required this.task, required this.theme, required this.s});
  final DemoCountTask task;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _qtyChip(theme, s, 'Expected', task.expectedQty),
        SizedBox(width: s.sm),
        _qtyChip(theme, s, 'Counted', task.countedQty ?? 0, optional: task.countedQty == null),
      ],
    );
  }

  Widget _qtyChip(ThemeData theme, UiV1SpacingTokens s, String label, int value, {bool optional = false}) {
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
          Text(optional && value == 0 ? '—' : '$value', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _VarianceBlock extends StatelessWidget {
  const _VarianceBlock({required this.task, required this.theme, required this.s});
  final DemoCountTask task;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    if (task.countedQty == null) {
      return Text('—', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    final v = task.varianceQty;
    Color? color;
    if (v > 0) color = theme.colorScheme.primary;
    if (v < 0) color = theme.colorScheme.error;
    return Text(
      '$v',
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: color),
    );
  }
}

class _ReasonBlock extends StatelessWidget {
  const _ReasonBlock({required this.task, required this.theme, required this.s});
  final DemoCountTask task;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  @override
  Widget build(BuildContext context) {
    final reason = task.reasonCode;
    if (reason == null || reason.isEmpty) {
      return Text('—', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return Text(reason, style: theme.textTheme.bodyMedium);
  }
}

/// Events timeline (same style as movement details).
class _CountTaskEventsTimeline extends StatelessWidget {
  const _CountTaskEventsTimeline({required this.events, required this.theme, required this.s});
  final List<DemoEvent> events;
  final ThemeData theme;
  final UiV1SpacingTokens s;

  static String _formatTs(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _eventCodeToLabel(String code) {
    const map = {
      'count_created': 'Created',
      'count_released': 'Released',
      'count_counted': 'Counted',
      'count_posted': 'Posted',
      'count_cancelled': 'Cancelled',
    };
    return map[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Text('No events', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    final tokens = Theme.of(context).brightness == Brightness.dark ? UiV1Tokens.dark : UiV1Tokens.light;
    const laneWidth = 20.0;
    const dotSize = 10.0;
    const lineWidth = 2.0;
    final r = UiV1RadiusTokens.standard;

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
