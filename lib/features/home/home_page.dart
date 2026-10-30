import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/entities/models.dart';
import '../../presentation/session/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';
import '../shell/dashboard_shell.dart';

enum HomeMode { dashboard, analytics }

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.mode = HomeMode.dashboard});

  final HomeMode mode;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AnalyticsOverview? _data;
  var _loading = true;
  String? _error;
  int? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<SessionBloc>().workspaceId;
    if (id != null && id != _loadedFor) {
      _loadedFor = id;
      _load(id);
    }
  }

  Future<void> _load(int id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<AnalyticsRepository>().analytics(id);
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) {
        setState(() {
          _data = null;
          _error = errorText(error);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isEmpty(AnalyticsOverview data) {
    return data.conversations == 0 &&
        data.leads == 0 &&
        data.sales == 0 &&
        data.revenue == 0 &&
        data.conversationGrowth.isEmpty &&
        data.customerByStatus.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final analytics = widget.mode == HomeMode.analytics;
    final workspace = context.watch<SessionBloc>().workspace;
    if (_loading) {
      if (analytics) {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(title: 'گزارش‌ها', description: 'آمار ۱۴ روز گذشته فضای کاری'),
            Expanded(child: _OverviewSkeleton()),
          ],
        );
      }
      return const _OverviewSkeleton();
    }
    final data = _data;
    final empty = _error == null && (data == null || _isEmpty(data));
    final header = analytics
        ? const PageHeader(title: 'گزارش‌ها', description: 'آمار ۱۴ روز گذشته فضای کاری')
        : _Greeting(name: workspace?.name ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: empty || _error != null
              ? (_error != null
                  ? ErrorView(message: _error!, onRetry: () {
                      final id = _loadedFor;
                      if (id != null) _load(id);
                    })
                  : const EmptyView(title: 'آماری برای نمایش نیست'))
              : _OverviewBody(data: data!),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: dt.coral, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text('سلام، $name', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
          ],
        ),
        const SizedBox(height: 6),
        Text('نمای کلی عملکرد دایرکت شما — ۱۴ روز گذشته', style: TextStyle(color: dt.textMuted, height: 1.6)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => openDashboardRoute(context, '/dashboard/inbox'),
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text('صندوق ورودی'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const StadiumBorder(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => openDashboardRoute(context, '/dashboard/analytics'),
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
      ],
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.data});

  final AnalyticsOverview data;

  @override
  Widget build(BuildContext context) {
    final maxStatus = data.customerByStatus.fold<int>(0, (max, point) => point.value > max ? point.value : max);
    return ListView(
      children: [
        _StatGrid(children: [
          _Stat(
            icon: Icons.chat_bubble_outline,
            label: 'مکالمات',
            value: faGrouped(data.conversations),
            hint: _weekHint(data.conversationsWeekChange),
            positive: (data.conversationsWeekChange ?? 0) >= 0,
          ),
          _Stat(
            icon: Icons.person_outline,
            label: 'لیدها',
            value: faGrouped(data.leads),
            hint: _weekHint(data.leadsWeekChange),
            positive: (data.leadsWeekChange ?? 0) >= 0,
          ),
          _Stat(icon: Icons.trending_up, label: 'نرخ تبدیل', value: '${faDigits(data.conversionRate.toStringAsFixed(0))}٪'),
          _Stat(icon: Icons.receipt_long_outlined, label: 'فروش', value: faGrouped(data.sales)),
        ]),
        const SizedBox(height: 10),
        _Stat(icon: Icons.description_outlined, label: 'درآمد', value: toman(data.revenue), wide: true),
        const SizedBox(height: 10),
        _StatGrid(children: [
          _Stat(icon: Icons.auto_awesome_outlined, label: 'حل توسط هوش مصنوعی', value: '${faDigits(data.aiResolutionRate.toStringAsFixed(0))}٪'),
          _Stat(icon: Icons.inventory_2_outlined, label: 'محصول فعال', value: faGrouped(data.activeProducts)),
        ]),
        const SizedBox(height: 12),
        if (data.conversationGrowth.isNotEmpty) _GrowthChart(points: data.conversationGrowth),
        if (data.customerByStatus.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('مشتریان بر اساس وضعیت', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  for (final point in data.customerByStatus)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(width: 52, child: Text(faLabel(customerStatusLabels, point.label), style: const TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: maxStatus == 0 ? 0 : point.value / maxStatus,
                                minHeight: 8,
                                backgroundColor: context.dt.surfaceMuted,
                                color: context.dt.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(width: 28, child: Text(faInt(point.value), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SectionTitle(title: 'دسترسی سریع'),
        _StatGrid(children: [
          _Quick(icon: Icons.forum_outlined, title: 'صندوق ورودی', caption: 'پاسخ‌های آماده و گفتگو', onTap: () => openDashboardRoute(context, '/dashboard/inbox')),
          _Quick(icon: Icons.view_carousel_outlined, title: 'ویترین ساز', caption: 'کارت محصول در دایرکت', onTap: () => openDashboardRoute(context, '/dashboard/vitrin')),
          _Quick(icon: Icons.people_outline, title: 'مشتریان', caption: 'مدیریت مشتریان و لیدها', onTap: () => openDashboardRoute(context, '/dashboard/customers')),
          _Quick(icon: Icons.mode_comment_outlined, title: 'کامنت هوشمند', caption: 'پاسخ خودکار به کامنت', onTap: () => openDashboardRoute(context, '/dashboard/automation')),
        ]),
      ],
    );
  }

  String? _weekHint(int? change) {
    if (change == null) return null;
    return '${faInt(change.abs())}٪ نسبت به هفته قبل';
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
  const _Stat({required this.icon, required this.label, required this.value, this.hint, this.positive = true, this.wide = false});

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final bool positive;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(color: dt.textMuted, fontSize: 13, fontWeight: FontWeight.w600))),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: dt.primary50, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 16, color: dt.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: wide ? 22 : 26, color: dt.text, height: 1.2)),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!, style: TextStyle(color: positive ? dt.success : dt.error, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4)),
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
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: dt.primary50, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: dt.primary, size: 20),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(caption, style: TextStyle(color: dt.textMuted, fontSize: 12, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 10);
    const pair = Row(
      children: [
        Expanded(child: SkeletonBox(height: 108, radius: 16)),
        SizedBox(width: 10),
        Expanded(child: SkeletonBox(height: 108, radius: 16)),
      ],
    );
    return ListView(
      children: const [
        SkeletonBox(width: 180, height: 22, radius: 8),
        gap,
        SkeletonBox(width: 220, height: 12, radius: 8),
        SizedBox(height: 16),
        pair,
        gap,
        pair,
        gap,
        SkeletonBox(height: 88, radius: 16),
        gap,
        pair,
        SizedBox(height: 12),
        SkeletonBox(height: 180, radius: 16),
      ],
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
