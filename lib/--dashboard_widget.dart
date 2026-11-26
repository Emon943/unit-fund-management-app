import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_widget.dart';

enum DashPage { dashboard, subscription, surrender }

class DashboardWidget extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const DashboardWidget({
    super.key,
    required this.token,
    required this.user,
  });

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  DashPage _page = DashPage.dashboard;

  static const double _wideBreakpoint = 900;
  static const double _sidebarWidth = 260;

  String _s(String key) => (widget.user[key] ?? '-').toString();

  String get _title {
    switch (_page) {
      case DashPage.dashboard:
        return 'Dashboard';
      case DashPage.subscription:
        return 'Subscription Report';
      case DashPage.surrender:
        return 'Surrender Report';
    }
  }

  void _select(DashPage page, {bool closeDrawer = false}) {
    setState(() => _page = page);
    if (closeDrawer) Navigator.of(context).pop();
  }

  void _logout() {
    loggedInUser.value = null;
    passwordController.clear();
    errorMessage.value = null;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginWidget()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _wideBreakpoint;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(_s('name')),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      // Small screens: sidebar becomes a drawer.
      drawer: isWide
          ? null
          : Drawer(child: _Sidebar(page: _page, onSelect: (p) => _select(p, closeDrawer: true))),
      body: Row(
        children: [
          // LEFT SIDE
          if (isWide)
            SizedBox(
              width: _sidebarWidth,
              child: _Sidebar(page: _page, onSelect: _select),
            ),

          // RIGHT SIDE
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_page) {
      case DashPage.dashboard:
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            _InvestorInfoCard(
              rows: [
                _InfoRow('Investor ID', _s('registration_no')),
                _InfoRow('Name', _s('name')),
                _InfoRow('Bank Name', _s('bank_name')),
                _InfoRow('Bank A/C', _s('account_no')),
              ],
            ),
            _FundRateCard(
              regNo: _s('registration_no'),
              token: widget.token,
            ),
          ],
        );
      case DashPage.subscription:
      // TODO: call your subscription report API using widget.token
        return const _ReportPlaceholder(title: 'Subscription Report');
      case DashPage.surrender:
      // TODO: call your surrender report API using widget.token
        return const _ReportPlaceholder(title: 'Surrender Report');
    }
  }
}

// ---------------------------------------------------------------------------
// LEFT SIDE: navigation menu
// ---------------------------------------------------------------------------
class _Sidebar extends StatelessWidget {
  final DashPage page;
  final ValueChanged<DashPage> onSelect;

  const _Sidebar({required this.page, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final reportOpen =
        page == DashPage.subscription || page == DashPage.surrender;

    return Material(
      color: Colors.white,
      elevation: 2,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Dashboard'),
            selected: page == DashPage.dashboard,
            selectedTileColor: Colors.blue.shade50,
            onTap: () => onSelect(DashPage.dashboard),
          ),
          ExpansionTile(
            key: PageStorageKey('report_menu_$reportOpen'),
            initiallyExpanded: reportOpen,
            leading: const Icon(Icons.info_outline),
            title: const Text('Investor Report'),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                title: const Text('Subscription Report'),
                selected: page == DashPage.subscription,
                selectedTileColor: Colors.blue.shade50,
                onTap: () => onSelect(DashPage.subscription),
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                title: const Text('Surrender Report'),
                selected: page == DashPage.surrender,
                selectedTileColor: Colors.blue.shade50,
                onTap: () => onSelect(DashPage.surrender),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RIGHT SIDE: investor info
// ---------------------------------------------------------------------------
class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}

class _InvestorInfoCard extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InvestorInfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 460),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Investor Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 28),
                Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    for (final r in rows)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 24, top: 0, bottom: 8),
                            child: Text(
                              '${r.label}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SelectableText(r.value),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportPlaceholder extends StatelessWidget {
  final String title;

  const _ReportPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            '$title will appear here',
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RIGHT SIDE: CAPM fund rate (next to investor information)
// ---------------------------------------------------------------------------
class _FundRateCard extends StatefulWidget {
  final String regNo;
  final String token;

  const _FundRateCard({required this.regNo, required this.token});

  @override
  State<_FundRateCard> createState() => _FundRateCardState();
}

class _FundRateCardState extends State<_FundRateCard> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final response = await http
        .post(
      Uri.parse('${LoginWidget.baseUrl}/capm-fund-rate'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'regno': widget.regNo,
        'api_token': widget.token,
      }),
    )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic> body = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(
          body['message']?.toString() ?? 'Failed to load fund rates');
    }

    // API may return a single object or a list of funds.
    final data = body['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) return [data];
    return [];
  }

  void _retry() => setState(() => _future = _load());

  String _fmt(dynamic v) {
    if (v == null) return '-';
    if (v is num) return v.toStringAsFixed(2);
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 560),
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fund Rate',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 28),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snap.hasError) {
                      final msg = snap.error
                          .toString()
                          .replaceFirst('Exception: ', '');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg,
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      );
                    }

                    final rates = snap.data ?? [];
                    if (rates.isEmpty) {
                      return const Text('No fund rate available');
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle:
                        const TextStyle(fontWeight: FontWeight.bold),
                        columns: const [
                          DataColumn(label: Text('Fund Name')),
                          DataColumn(
                              label: Text('Sale / Subscription Price'),
                              numeric: true),
                          DataColumn(
                              label: Text('Re-Purchase / Surrender Price'),
                              numeric: true),
                        ],
                        rows: [
                          for (final r in rates)
                            DataRow(cells: [
                              DataCell(Text(
                                  (r['PORTFOLIO_NAME'] ?? 'CAPM Fund')
                                      .toString())),
                              DataCell(Text(_fmt(r['BUY_RATE']))),
                              DataCell(Text(_fmt(r['SELL_RATE']))),
                            ]),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
