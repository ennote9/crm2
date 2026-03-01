// Order Details (Object Page) v1 — UI skeleton per ObjectPage_Order_Spec.
// Sticky header, summary strip, tabs. No business logic / available_actions.

import 'package:flutter/material.dart';

import '../../components/chips/index.dart';
import '../../theme/density.dart';
import '../../theme/tokens.dart';

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
class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({
    super.key,
    required this.payload,
  });

  final OrderDetailsPayload payload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final density = UiV1DensityTokens.dense;
    final tokens = Theme.of(context).brightness == Brightness.dark
        ? UiV1Tokens.dark
        : UiV1Tokens.light;
    final s = tokens.spacing;

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
                                payload.orderNo,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              SizedBox(width: s.sm),
                              UiV1StatusChip(
                                label: payload.status,
                                variant: UiV1StatusChip.variantFromStatus(payload.status),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Next step (placeholder)')),
                            );
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: Size(0, density.buttonHeight),
                          ),
                          child: const Text('Next step'),
                        ),
                        SizedBox(width: s.xs),
                        IconButton(
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('More (placeholder)')),
                            );
                          },
                          tooltip: 'More',
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
                  _TabStub(
                    title: 'Lines',
                    mockLines: ['Line 1', 'Line 2', 'Line 3'],
                  ),
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
