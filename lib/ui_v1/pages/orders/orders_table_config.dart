// Orders table config for Unified Table Platform v1 (pilot).

import 'package:flutter/material.dart';

import '../../components/chips/index.dart';
import '../../components/table_platform/index.dart';
import '../../demo_data/demo_data.dart';

const String _kOrdersTableId = 'orders';

/// Saved view ids for Orders.
const String kOrdersViewAll = 'all';
const String kOrdersViewOnHold = 'on_hold';
const String kOrdersViewShortage = 'shortage';
const String kOrdersViewToday = 'today';

UnifiedTableConfig<DemoOrder> createOrdersTableConfig(void Function(DemoOrder) rowOpen) {
  return UnifiedTableConfig<DemoOrder>(
    tableId: _kOrdersTableId,
    columns: _ordersColumns,
    rowIdGetter: (o) => o.id,
    searchFields: ['orderNo', 'warehouse', 'status'],
    defaultSorts: const [],
    defaultDensity: UnifiedTableDensity.dense,
    defaultVisibleColumnIds: const ['orderNo', 'status', 'warehouse', 'created'],
    defaultStatsVisible: false,
    availableMetrics: _ordersMetrics,
    defaultMetricIds: const ['total', 'inProgress', 'onHold', 'shortage'],
    rowOpen: rowOpen,
    savedViews: _ordersSavedViews,
  );
}

final List<UnifiedTableColumn<DemoOrder>> _ordersColumns = [
  UnifiedTableColumn<DemoOrder>(
    id: 'orderNo',
    label: 'Order No',
    flex: 3,
    sortable: true,
    filterable: true,
    filterType: UnifiedColumnFilterType.text,
    valueGetter: (o) => o.orderNo,
    cellBuilder: (r) => Text(r.orderNo, overflow: TextOverflow.ellipsis, maxLines: 1),
  ),
  UnifiedTableColumn<DemoOrder>(
    id: 'status',
    label: 'Status',
    flex: 2,
    sortable: true,
    filterable: true,
    filterType: UnifiedColumnFilterType.enum_,
    valueGetter: (o) => o.status,
    cellBuilder: (r) => UiV1StatusChip(
      label: r.status,
      variant: UiV1StatusChip.variantFromStatus(r.status),
    ),
  ),
  UnifiedTableColumn<DemoOrder>(
    id: 'warehouse',
    label: 'Warehouse',
    flex: 2,
    sortable: true,
    filterable: true,
    filterType: UnifiedColumnFilterType.enum_,
    valueGetter: (o) => o.warehouse,
    cellBuilder: (r) => Text(r.warehouse, overflow: TextOverflow.ellipsis, maxLines: 1),
  ),
  UnifiedTableColumn<DemoOrder>(
    id: 'created',
    label: 'Created',
    flex: 2,
    sortable: true,
    filterable: true,
    filterType: UnifiedColumnFilterType.date,
    valueGetter: (o) => o.createdAt,
    cellBuilder: (r) => Text(r.createdAt, overflow: TextOverflow.ellipsis, maxLines: 1),
  ),
];

final List<UnifiedStatsMetricDefinition<DemoOrder>> _ordersMetrics = [
  UnifiedStatsMetricDefinition<DemoOrder>(
    id: 'total',
    label: 'Total',
    type: UnifiedStatsMetricType.count,
  ),
  UnifiedStatsMetricDefinition<DemoOrder>(
    id: 'inProgress',
    label: 'In progress',
    type: UnifiedStatsMetricType.count,
    predicate: (o) =>
        o.status == 'Released' ||
        o.status == 'Allocated' ||
        o.status == 'Allocating' ||
        o.status == 'Picking' ||
        o.status == 'Packing',
  ),
  UnifiedStatsMetricDefinition<DemoOrder>(
    id: 'onHold',
    label: 'On Hold',
    type: UnifiedStatsMetricType.count,
    predicate: (o) => o.isOnHold || o.status == 'On Hold',
  ),
  UnifiedStatsMetricDefinition<DemoOrder>(
    id: 'shortage',
    label: 'Shortage',
    type: UnifiedStatsMetricType.count,
    predicate: (o) => o.status == 'Shortage',
  ),
];

List<SavedTableView> get _ordersSavedViews => [
      SavedTableView(
        id: kOrdersViewAll,
        tableId: _kOrdersTableId,
        name: 'All',
        filters: const [],
        sorts: const [],
        visibleColumnIds: const ['orderNo', 'status', 'warehouse', 'created'],
        columnOrder: const ['orderNo', 'status', 'warehouse', 'created'],
        density: UnifiedTableDensity.dense,
        statsVisible: false,
        selectedMetricIds: const ['total', 'inProgress', 'onHold', 'shortage'],
      ),
      SavedTableView(
        id: kOrdersViewOnHold,
        tableId: _kOrdersTableId,
        name: 'On Hold',
        filters: [
          UnifiedFilterDescriptor(
            columnId: 'status',
            operator: UnifiedFilterOperator.equals,
            value: 'On Hold',
          ),
        ],
        sorts: const [],
        visibleColumnIds: const ['orderNo', 'status', 'warehouse', 'created'],
        columnOrder: const ['orderNo', 'status', 'warehouse', 'created'],
        density: UnifiedTableDensity.dense,
        statsVisible: false,
        selectedMetricIds: const ['total', 'inProgress', 'onHold', 'shortage'],
      ),
      SavedTableView(
        id: kOrdersViewShortage,
        tableId: _kOrdersTableId,
        name: 'Shortage',
        filters: [
          UnifiedFilterDescriptor(
            columnId: 'status',
            operator: UnifiedFilterOperator.equals,
            value: 'Shortage',
          ),
        ],
        sorts: const [],
        visibleColumnIds: const ['orderNo', 'status', 'warehouse', 'created'],
        columnOrder: const ['orderNo', 'status', 'warehouse', 'created'],
        density: UnifiedTableDensity.dense,
        statsVisible: false,
        selectedMetricIds: const ['total', 'inProgress', 'onHold', 'shortage'],
      ),
      SavedTableView(
        id: kOrdersViewToday,
        tableId: _kOrdersTableId,
        name: 'Today',
        filters: [
          UnifiedFilterDescriptor(
            columnId: 'created',
            operator: UnifiedFilterOperator.startsWith,
            value: '2025-01',
          ),
        ],
        sorts: const [],
        visibleColumnIds: const ['orderNo', 'status', 'warehouse', 'created'],
        columnOrder: const ['orderNo', 'status', 'warehouse', 'created'],
        density: UnifiedTableDensity.dense,
        statsVisible: false,
        selectedMetricIds: const ['total', 'inProgress', 'onHold', 'shortage'],
      ),
    ];
