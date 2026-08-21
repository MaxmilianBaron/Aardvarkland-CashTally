import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../data/currency_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/cash_count_session.dart';
import '../models/count_mode.dart';
import '../state/app_controller.dart';
import '../state/app_scope.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String? _currencyCode;
  bool _differencesOnly = false;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final sessions = controller.sessions
        .where(_matches)
        .toList(growable: false);
    final availableCodes =
        controller.sessions.map((item) => item.currencyCode).toSet().toList()
          ..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('history')),
        actions: <Widget>[
          IconButton(
            tooltip: context.tr('clearFilters'),
            onPressed: _hasFilters ? _clearFilters : null,
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: context.tr('searchHistory'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _currencyCode,
                        decoration: InputDecoration(
                          labelText: context.tr('currency'),
                          isDense: true,
                        ),
                        items: <DropdownMenuItem<String?>>[
                          DropdownMenuItem<String?>(
                            child: Text(context.tr('allCurrencies')),
                          ),
                          ...availableCodes.map(
                            (code) => DropdownMenuItem<String?>(
                              value: code,
                              child: Text(code),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _currencyCode = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(
                        _dateRange == null
                            ? context.tr('dateRange')
                            : context.tr('dateRangeActive'),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _differencesOnly,
                  onChanged: (value) =>
                      setState(() => _differencesOnly = value ?? false),
                  title: Text(context.tr('differencesOnly')),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: sessions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        context.tr(
                          controller.sessions.isEmpty
                              ? 'historyEmpty'
                              : 'noHistoryMatches',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _sessionCard(context, controller, sessions[index]),
                  ),
          ),
        ],
      ),
    );
  }

  bool get _hasFilters =>
      _searchController.text.isNotEmpty ||
      _currencyCode != null ||
      _differencesOnly ||
      _dateRange != null;

  bool _matches(CashCountSession session) {
    if (_currencyCode != null && session.currencyCode != _currencyCode) {
      return false;
    }
    final date = session.updatedAt;
    if (_dateRange != null) {
      final endExclusive = _dateRange!.end.add(const Duration(days: 1));
      if (date.isBefore(_dateRange!.start) || !date.isBefore(endExclusive)) {
        return false;
      }
    }
    final currency = session.currencyFor(
      CurrencyCatalog.byCode(session.currencyCode),
    );
    if (_differencesOnly &&
        (session.differenceMinorUnits(currency) ?? 0) == 0) {
      return false;
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    return <String>[
      session.documentNumber,
      session.currencyCode,
      session.businessName,
      session.locationName,
      session.tillName,
      session.cashierName,
      session.managerName,
      session.shiftName,
      session.note,
      session.posReport?.id ?? '',
      session.posReport?.sourceFileName ?? '',
      session.posReport?.tillName ?? '',
      session.posReport?.cashierName ?? '',
    ].any((value) => value.toLowerCase().contains(query));
  }

  Widget _sessionCard(
    BuildContext context,
    AppController controller,
    CashCountSession session,
  ) {
    final currency = session.currencyFor(
      CurrencyCatalog.byCode(session.currencyCode),
    );
    final total = session.totalMinorUnits(currency);
    final difference = session.differenceMinorUnits(currency);
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        title: Text(
          currency.formatMinor(total, localeCode: localeCode),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(
          '${session.currencyCode} · '
          '${AppFormatters.dateTime(session.updatedAt, localeCode: localeCode)}'
          '\n${context.tr(session.mode == CountMode.quick ? 'quickCount' : 'professionalClose')}'
          '${session.tillName.trim().isEmpty ? '' : ' · ${session.tillName.trim()}'}'
          '${difference == null ? '' : '\n${context.tr('difference')}: ${currency.formatMinor(difference, localeCode: localeCode)}'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: context.tr('delete'),
              onPressed: () => _deleteSession(context, controller, session),
              icon: const Icon(Icons.delete_outline),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SessionDetailScreen(sessionId: session.id),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (selected != null && mounted) {
      setState(() => _dateRange = selected);
    }
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _currencyCode = null;
      _differencesOnly = false;
      _dateRange = null;
    });
  }

  Future<void> _deleteSession(
    BuildContext context,
    AppController controller,
    CashCountSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('deleteTitle')),
        content: Text(context.tr('deleteBody')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('keep')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await controller.deleteSession(session.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('deleted'))));
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('deleteFailed'))));
      }
    }
  }
}
