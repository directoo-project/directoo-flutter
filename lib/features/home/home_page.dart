import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../data/directoo_api.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AnalyticsOverview? _data;
  var _loading = true;
  int? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<SessionController>().workspaceId;
    if (id != null && id != _loadedFor) {
      _loadedFor = id;
      _load(id);
    }
  }

  Future<void> _load(int id) async {
    setState(() => _loading = true);
    try {
      final data = await context.read<DirectooApi>().analytics(id);
      if (mounted) setState(() => _data = data);
    } catch (_) {
      if (mounted) setState(() => _data = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<SessionController>().workspace;
    final dt = context.dt;
    if (_loading) return const LoadingView();
    final data = _data;
    return ListView(
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: dt.coral, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text('سلام، ${workspace?.name ?? ''}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
          ],
        ),
        const SizedBox(height: 6),
        Text('نمای کلی عملکرد دایرکت شما — ۱۴ روز گذشته', style: TextStyle(color: dt.textMuted)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/dashboard/inbox'),
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text('صندوق ورودی'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const StadiumBorder(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/dashboard/analytics'),
              icon: const Icon(Icons.insights_outlined, size: 18),
              label: const Text('گزارش کامل'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (data == null)
          const EmptyView(title: 'آماری برای نمایش نیست')
        else ...[
          _StatGrid(children: [
            _Stat(label: 'مکالمات', value: faInt(data.conversations), hint: data.conversationsWeekChange == null ? null : '${faInt(data.conversationsWeekChange!.abs())}٪ نسبت به هفته قبل'),
            _Stat(label: 'لیدها', value: faInt(data.leads), hint: data.leadsWeekChange == null ? null : '${faInt(data.leadsWeekChange!.abs())}٪ نسبت به هفته قبل'),
            _Stat(label: 'نرخ تبدیل', value: '${faDigits(data.conversionRate.toStringAsFixed(0))}٪'),
            _Stat(label: 'فروش', value: faInt(data.sales)),
            _Stat(label: 'درآمد', value: toman(data.revenue)),
            _Stat(label: 'حل توسط هوش مصنوعی', value: '${faDigits(data.aiResolutionRate.toStringAsFixed(0))}٪'),
            _Stat(label: 'محصول فعال', value: faInt(data.activeProducts)),
          ]),
          const SizedBox(height: 12),
          if (data.conversationGrowth.isNotEmpty) _GrowthChart(points: data.conversationGrowth),
          if (data.customerByStatus.isNotEmpty)
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مشتریان بر اساس وضعیت', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  for (final point in data.customerByStatus)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(faLabel(customerStatusLabels, point.label))),
                          Text(faInt(point.value), style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Text('دسترسی سریع', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          _Quick(icon: Icons.forum_outlined, title: 'صندوق ورودی', caption: 'پاسخ‌های آماده و گفتگو', onTap: () => context.go('/dashboard/inbox')),
          _Quick(icon: Icons.view_carousel_outlined, title: 'ویترین ساز', caption: 'کارت محصول در دایرکت', onTap: () => context.go('/dashboard/vitrin')),
          _Quick(icon: Icons.people_outline, title: 'مشتریان', caption: 'مدیریت مشتریان و لیدها', onTap: () => context.go('/dashboard/customers')),
          _Quick(icon: Icons.mode_comment_outlined, title: 'کامنت هوشمند', caption: 'پاسخ خودکار به کامنت', onTap: () => context.go('/dashboard/automation')),
        ],
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: dt.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: dt.text, height: 1.2)),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!, style: TextStyle(color: dt.success, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.title, required this.caption, required this.onTap});

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SurfaceCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: dt.primary50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: dt.primary, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(caption),
          trailing: Icon(Icons.chevron_left, color: dt.textSubtle),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final color = context.dt.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('رشد مکالمات', style: TextStyle(fontWeight: FontWeight.w800))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: context.dt.surfaceMuted, borderRadius: BorderRadius.circular(999)),
                  child: Text('۱۴ روز گذشته', style: TextStyle(color: context.dt.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
                      spots: [
                        for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value.toDouble()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
