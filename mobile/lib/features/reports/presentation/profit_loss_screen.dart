import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/formatters.dart';
import '../../auth/presentation/user_menu.dart';
import '../data/report_repository.dart';

class ProfitLossScreen extends ConsumerStatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  ConsumerState<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends ConsumerState<ProfitLossScreen> {
  late int _month = DateTime.now().month;
  late int _year = DateTime.now().year;
  Future<ProfitLossReport>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = ref.read(reportRepositoryProvider).profitLoss(month: _month, year: _year);
    });
  }

  String _monthName(int m) {
    const names = <String>[
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: scheme.primary),
            const SizedBox(width: 8),
            Text('Laporan Laba Rugi', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: const <Widget>[UserMenu()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Filter Period
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.calendar_month_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Bulan', isDense: true),
                    items: <DropdownMenuItem<int>>[
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem<int>(value: m, child: Text(_monthName(m))),
                    ],
                    onChanged: (v) {
                      setState(() => _month = v ?? _month);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Tahun', isDense: true),
                    items: <DropdownMenuItem<int>>[
                      for (var y = DateTime.now().year - 3; y <= DateTime.now().year + 1; y++)
                        DropdownMenuItem<int>(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) {
                      setState(() => _year = v ?? _year);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<ProfitLossReport>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
                        const SizedBox(height: 8),
                        Text('Gagal memuat data', style: TextStyle(color: scheme.error)),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  );
                }
                final report = snapshot.data;
                if (report == null) return const SizedBox.shrink();
                return _ReportBody(report: report, month: _month, year: _year);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report, required this.month, required this.year});

  final ProfitLossReport report;
  final int month;
  final int year;

  @override
  Widget build(BuildContext context) {
    final isProfit = report.profit >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Profit highlight card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isProfit
                    ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
                    : [Colors.red.shade800, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: Colors.white70, size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isProfit ? 'Laba Bersih' : 'Rugi Bersih',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatRupiah(report.profit.abs()),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_monthName(month)} $year',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Summary cards
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryCard(
                  title: 'Penjualan',
                  value: report.salesTotal,
                  count: report.salesCount,
                  color: Colors.green.shade600,
                  icon: Icons.trending_up_rounded,
                  bgColor: Colors.green.shade50,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'Pembelian',
                  value: report.purchasesTotal,
                  count: report.purchasesCount,
                  color: Colors.orange.shade700,
                  icon: Icons.shopping_cart_rounded,
                  bgColor: Colors.orange.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          if (report.daily.isNotEmpty) ...[
            Text(
              'Grafik Harian',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            // Legend
            Row(
              children: [
                _LegendDot(color: Colors.green.shade600, label: 'Penjualan'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.orange.shade700, label: 'Pembelian'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  barGroups: <BarChartGroupData>[
                    for (var i = 0; i < report.daily.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: <BarChartRodData>[
                          BarChartRodData(
                            toY: report.daily[i].sales,
                            color: Colors.green.shade600,
                            width: 7,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: report.daily[i].purchases,
                            color: Colors.orange.shade700,
                            width: 7,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                        barsSpace: 2,
                      ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= report.daily.length) return const SizedBox.shrink();
                          final d = report.daily[idx].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              d.length >= 10 ? d.substring(8) : d,
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0 ? 'Jual' : 'Beli';
                        return BarTooltipItem(
                          '$label\n${formatRupiah(rod.toY)}',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada data pada periode ini.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = <String>[
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return names[m - 1];
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.count,
    required this.color,
    required this.icon,
    required this.bgColor,
  });

  final String title;
  final double value;
  final int count;
  final Color color;
  final IconData icon;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(value),
            style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14),
          ),
          Text('$count transaksi', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
