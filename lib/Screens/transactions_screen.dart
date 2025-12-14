import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Services/transaction_service.dart';
import '../theme.dart';
import '../models/transaction.dart';

/// Provide a fallback `messageId` getter for `Transaction` in case the model
/// does not expose such a field; this avoids compile errors while keeping a
/// deterministic string to display (override or remove if the real model
/// exposes a proper identifier).
extension TransactionMessageId on Transaction {
  String get messageId => toString();
}

enum Timeframe { daily, weekly, monthly, yearly, all }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _service = TransactionService();
  late Future<List<Transaction>> _future;

  // Filters
  Timeframe _timeframe = Timeframe.monthly;
  TransactionType? _type; // 'debit', 'credit', or null = All
  String _targetQuery = '';
  RangeValues? _amountRange; // dynamic based on data
  RangeValues? _currentAmountRange; // current selection
  int _sortIndex = 0; // 0 newest, 1 oldest, 2 amount desc, 3 amount asc

  // Cached data
  List<Transaction> _all = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Transaction>> _load() async {
    final items = await _service.fetchTransactions();
    if (!mounted) return items;
    setState(() {
      _all = items;
      if (items.isNotEmpty) {
        final minAmount = items
            .map((e) => e.amount)
            .reduce((a, b) => a < b ? a : b);
        final maxAmount = items
            .map((e) => e.amount)
            .reduce((a, b) => a > b ? a : b);
        _amountRange = RangeValues(
          minAmount.floorToDouble(),
          maxAmount.ceilToDouble(),
        );
        _currentAmountRange = _amountRange;
      }
    });
    return items;
  }

  // Compute filtered list
  List<Transaction> get _filtered {
    var list = _all;

    // Timeframe filter
    final now = DateTime.now();
    DateTime start;
    switch (_timeframe) {
      case Timeframe.daily:
        start = DateTime(now.year, now.month, now.day);
        list = list.where((e) => e.time.isAfter(start)).toList();
        break;
      case Timeframe.weekly:
        final weekday = now.weekday; // 1 Mon .. 7 Sun
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: weekday - 1));
        list = list.where((e) => e.time.isAfter(start)).toList();
        break;
      case Timeframe.monthly:
        start = DateTime(now.year, now.month);
        list = list.where((e) => e.time.isAfter(start)).toList();
        break;
      case Timeframe.yearly:
        start = DateTime(now.year);
        list = list.where((e) => e.time.isAfter(start)).toList();
        break;
      case Timeframe.all:
        break;
    }

    // Type filter
    if (_type != null) {
      list = list.where((e) => e.type == _type).toList();
    }

    // Target query
    if (_targetQuery.isNotEmpty) {
      final q = _targetQuery.toLowerCase();
      list = list.where((e) => e.target.toLowerCase().contains(q)).toList();
    }

    // Amount range
    if (_currentAmountRange != null) {
      final min = _currentAmountRange!.start;
      final max = _currentAmountRange!.end;
      list = list.where((e) => e.amount >= min && e.amount <= max).toList();
    }

    // Sort
    list.sort((a, b) {
      switch (_sortIndex) {
        case 0:
          return b.time.compareTo(a.time); // newest
        case 1:
          return a.time.compareTo(b.time); // oldest
        case 2:
          return b.amount.compareTo(a.amount); // amount high-low
        case 3:
          return a.amount.compareTo(b.amount); // amount low-high
        default:
          return 0;
      }
    });

    return list;
  }

  double get _income => _filtered
      .where((e) => e.type == TransactionType.credit)
      .fold(0.0, (p, e) => p + e.amount);
  double get _spending => _filtered
      .where((e) => e.type == TransactionType.debit)
      .fold(0.0, (p, e) => p + e.amount);
  double get _net => _income - _spending;

  String _formatDate(DateTime dt) {
    return DateFormat('EEE, MMM d • h:mm a').format(dt);
  }

  String _formatCurrency(double value) {
    final f = NumberFormat.currency(symbol: '\$');
    return f.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = context.textStyles;
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions'), centerTitle: true),
      body: FutureBuilder<List<Transaction>>(
        future: _future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          return Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              children: [
                _FiltersBar(
                  timeframe: _timeframe,
                  onTimeframeChanged: (t) => setState(() => _timeframe = t),
                  type: _type,
                  onTypeChanged: (t) => setState(() => _type = t),
                  sortIndex: _sortIndex,
                  onSortChanged: (i) {
                    if (i != null) setState(() => _sortIndex = i);
                  },
                ),
                const SizedBox(height: 12),
                _SearchAndAmount(
                  targetQuery: _targetQuery,
                  onQueryChanged: (v) => setState(() => _targetQuery = v),
                  range: _currentAmountRange,
                  fullRange: _amountRange,
                  onRangeChanged: (v) =>
                      setState(() => _currentAmountRange = v),
                ),
                const SizedBox(height: 16),
                _TotalsRow(income: _income, spending: _spending, net: _net),
                const SizedBox(height: 12),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions match your filters.',
                            style: text.bodyLarge,
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = _filtered[index];
                            final isCredit = tx.type == TransactionType.credit;
                            final amountColor = isCredit
                                ? cs.primary
                                : cs.error;
                            final icon = isCredit
                                ? Icons.trending_up
                                : Icons.trending_down;
                            return Container(
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: cs.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          (isCredit
                                                  ? cs.primaryContainer
                                                  : cs.errorContainer)
                                              .withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: isCredit
                                          ? cs.onPrimaryContainer
                                          : cs.onErrorContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                tx.target,
                                                style:
                                                    text.titleMedium?.semiBold,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              (isCredit ? '+' : '-') +
                                                  _formatCurrency(tx.amount),
                                              style: text.titleMedium?.semiBold
                                                  .withColor(amountColor),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 16,
                                              color: cs.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatDate(tx.time),
                                              style: text.labelMedium
                                                  ?.withColor(
                                                    cs.onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons
                                                  .confirmation_number_outlined,
                                              size: 16,
                                              color: cs.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'ID ${tx.messageId}',
                                              style: text.labelMedium
                                                  ?.withColor(
                                                    cs.onSurfaceVariant,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons
                                                  .account_balance_wallet_outlined,
                                              size: 16,
                                              color: cs.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              tx.account,
                                              style: text.labelMedium
                                                  ?.withColor(
                                                    cs.onSurfaceVariant,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.timeframe,
    required this.onTimeframeChanged,
    required this.type,
    required this.onTypeChanged,
    required this.sortIndex,
    required this.onSortChanged,
  });

  final Timeframe timeframe;
  final ValueChanged<Timeframe> onTimeframeChanged;
  final TransactionType? type; // 'debit', 'credit', or null
  final ValueChanged<TransactionType?> onTypeChanged;
  final int sortIndex;
  final ValueChanged<int?> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = context.textStyles;
    Widget chip<T>({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return ChoiceChip(
        label: Text(label, style: text.labelLarge),
        selected: selected,
        onSelected: (_) => onTap(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        selectedColor: cs.primaryContainer,
        labelPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip(
                label: 'Today',
                selected: timeframe == Timeframe.daily,
                onTap: () => onTimeframeChanged(Timeframe.daily),
              ),
              const SizedBox(width: 8),
              chip(
                label: 'This Week',
                selected: timeframe == Timeframe.weekly,
                onTap: () => onTimeframeChanged(Timeframe.weekly),
              ),
              const SizedBox(width: 8),
              chip(
                label: 'This Month',
                selected: timeframe == Timeframe.monthly,
                onTap: () => onTimeframeChanged(Timeframe.monthly),
              ),
              const SizedBox(width: 8),
              chip(
                label: 'This Year',
                selected: timeframe == Timeframe.yearly,
                onTap: () => onTimeframeChanged(Timeframe.yearly),
              ),
              const SizedBox(width: 8),
              chip(
                label: 'All',
                selected: timeframe == Timeframe.all,
                onTap: () => onTimeframeChanged(Timeframe.all),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            DropdownButton<TransactionType?>(
              value: type,
              items: const [
                DropdownMenuItem(value: null, child: Text('All Types')),
                DropdownMenuItem(
                  value: TransactionType.debit,
                  child: Text('Debits'),
                ),
                DropdownMenuItem(
                  value: TransactionType.credit,
                  child: Text('Credits'),
                ),
              ],
              onChanged: onTypeChanged,
            ),
            const Spacer(),
            DropdownButton<int>(
              value: sortIndex,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Newest')),
                DropdownMenuItem(value: 1, child: Text('Oldest')),
                DropdownMenuItem(value: 2, child: Text('Amount • High → Low')),
                DropdownMenuItem(value: 3, child: Text('Amount • Low → High')),
              ],
              onChanged: onSortChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchAndAmount extends StatelessWidget {
  const _SearchAndAmount({
    required this.targetQuery,
    required this.onQueryChanged,
    required this.range,
    required this.fullRange,
    required this.onRangeChanged,
  });

  final String targetQuery;
  final ValueChanged<String> onQueryChanged;
  final RangeValues? range;
  final RangeValues? fullRange;
  final ValueChanged<RangeValues> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = context.textStyles;
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: cs.primary),
            hintText: 'Filter by target (recipient/sender)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          onChanged: onQueryChanged,
        ),
        if (range != null && fullRange != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Amount', style: text.labelLarge),
              const Spacer(),
              Text(
                '${range!.start.toStringAsFixed(0)} - ${range!.end.toStringAsFixed(0)}',
                style: text.labelLarge,
              ),
            ],
          ),
          RangeSlider(
            values: range!,
            min: fullRange!.start,
            max: fullRange!.end,
            divisions: (fullRange!.end - fullRange!.start)
                .clamp(1, 100)
                .toInt(),
            onChanged: onRangeChanged,
          ),
        ],
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.income,
    required this.spending,
    required this.net,
  });
  final double income;
  final double spending;
  final double net;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = context.textStyles;
    String currency(double v) => NumberFormat.currency(symbol: '\$').format(v);

    Widget card({
      required String label,
      required String value,
      required Color color,
      required IconData icon,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.labelMedium?.withColor(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(value, style: text.titleMedium?.semiBold),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card(
          label: 'Income',
          value: currency(income),
          color: cs.primary,
          icon: Icons.south_west,
        ),
        const SizedBox(width: 8),
        card(
          label: 'Spending',
          value: currency(spending),
          color: cs.error,
          icon: Icons.north_east,
        ),
        const SizedBox(width: 8),
        card(
          label: 'Net',
          value: currency(net),
          color: net >= 0 ? cs.primary : cs.error,
          icon: Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }
}
