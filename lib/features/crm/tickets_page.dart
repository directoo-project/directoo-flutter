import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../domain/repositories/tickets_repository.dart';
import '../../domain/entities/models.dart';
import '../../presentation/session/session_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final _search = TextEditingController();
  List<Ticket> _items = const [];
  var _status = 'all';
  var _loading = true;
  String? _error;
  int? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<SessionBloc>().workspaceId;
    if (id != null && id != _loadedFor) {
      _loadedFor = id;
      _load();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _loadedFor;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final items = await context.read<TicketsRepository>().tickets(
        id,
        status: _status,
        search: _search.text.trim(),
      );
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final subject = TextEditingController();
    final description = TextEditingController();
    var priority = 'medium';
    final created = await showFormSheet<bool>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'تیکت جدید',
              description: 'موضوع و شرح درخواست را بنویسید',
            ),
            TextField(
              controller: subject,
              decoration: const InputDecoration(labelText: 'موضوع'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'شرح'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'اولویت'),
              items: [
                for (final entry in ticketPriorityLabels.entries)
                  if (entry.key != 'all')
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
              ],
              onChanged: (value) =>
                  setLocal(() => priority = value ?? 'medium'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ثبت'),
            ),
          ],
        ),
      ),
    );
    if (created != true || !mounted) return;
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null || subject.text.trim().isEmpty) return;
    try {
      await context.read<TicketsRepository>().saveTicket(id, {
        'subject': subject.text.trim(),
        'description': description.text.trim(),
        'priority': priority,
        'status': 'open',
      });
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<SessionBloc>().permissions.canEditTickets;
    return Column(
      children: [
        PageHeader(
          title: 'تیکت‌ها',
          description: 'درخواست‌های پشتیبانی مشتریان',
          action: canEdit
              ? IconButton(onPressed: _create, icon: const Icon(Icons.add))
              : null,
        ),
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'جستجو در موضوع یا مشتری',
            prefixIcon: const Icon(Icons.search),
          ),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 12),
        _StatusFilters(
          selected: _status,
          onSelected: (value) {
            setState(() => _status = value);
            _load();
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
              ? const EmptyView(title: 'تیکتی نیست')
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _TicketCard(ticket: _items[index]),
                ),
        ),
      ],
    );
  }
}

class TicketDetailPage extends StatefulWidget {
  const TicketDetailPage({super.key, required this.id});

  final int id;

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  Ticket? _ticket;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final workspaceId = context.read<SessionBloc>().workspaceId;
    if (workspaceId == null) return;
    setState(() => _loading = true);
    try {
      final ticket = await context.read<TicketsRepository>().ticket(
        workspaceId,
        widget.id,
      );
      if (mounted) setState(() => _ticket = ticket);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send(String raw) async {
    final workspaceId = context.read<SessionBloc>().workspaceId;
    final text = raw.trim();
    if (workspaceId == null || text.isEmpty) return;
    try {
      await context.read<TicketsRepository>().addTicketComment(
        workspaceId,
        widget.id,
        text,
      );
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  Future<void> _setStatus(String status) async {
    final workspaceId = context.read<SessionBloc>().workspaceId;
    final ticket = _ticket;
    if (workspaceId == null || ticket == null) return;
    try {
      final updated = await context.read<TicketsRepository>().saveTicket(
        workspaceId,
        {'status': status},
        ticketId: ticket.id,
      );
      if (mounted) setState(() => _ticket = updated);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: 'تیکت', description: 'جزئیات درخواست'),
          Expanded(child: LoadingView()),
        ],
      );
    }
    if (_error != null && _ticket == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: 'تیکت', description: 'جزئیات درخواست'),
          Expanded(
            child: ErrorView(message: _error!, onRetry: _load),
          ),
        ],
      );
    }
    final ticket = _ticket!;
    final canEdit = context.watch<SessionBloc>().permissions.canEditTickets;
    final dt = context.dt;
    final me = context.read<SessionBloc>().user?.displayName ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TicketHeader(ticket: ticket, canEdit: canEdit, onStatus: _setStatus),
        Expanded(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 108),
                children: _bubbles(ticket, me, dt),
              ),
              MessageBar(
                messageBarHintText: 'پیام خود را بنویسید',
                messageBarColor: dt.surface,
                sendButtonColor: dt.primary,
                messageBarHintStyle: TextStyle(
                  color: dt.textSubtle,
                  fontSize: 14,
                ),
                textFieldTextStyle: TextStyle(
                  color: dt.text,
                  fontSize: 15,
                  height: 1.4,
                ),
                messageBarStyle: MessageBarStyle(
                  fillColor: dt.bgSubtle,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: dt.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: dt.primary, width: 1.4),
                  ),
                ),

                sendButton: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: dt.primary,
                    shape: BoxShape.circle,
                  ),
                  margin: EdgeInsets.only(right: 10),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.send_rounded,
                    color: dt.onPrimary,
                    size: 18,
                  ),
                ),
                onSend: _send,
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: TextStyle(color: dt.error, fontSize: 13),
            ),
          ),
      ],
    );
  }

  List<Widget> _bubbles(Ticket ticket, String me, DtColors dt) {
    final entries =
        <
          ({
            String sender,
            String name,
            String text,
            String? createdAt,
            bool mine,
          })
        >[
          if (ticket.description.trim().isNotEmpty)
            (
              sender: 'customer',
              name: ticket.customerName,
              text: ticket.description.trim(),
              createdAt: null,
              mine: false,
            ),
          for (final comment in ticket.comments)
            (
              sender: me.isNotEmpty && comment.authorName == me
                  ? 'me'
                  : comment.authorName,
              name: comment.authorName,
              text: comment.content,
              createdAt: comment.createdAt,
              mine: me.isNotEmpty && comment.authorName == me,
            ),
        ];
    if (entries.isEmpty) {
      return [
        BubbleNormal(
          text: 'بدون شرح',
          isSender: false,
          tail: true,
          color: dt.surface,
          textStyle: TextStyle(color: dt.textMuted, fontSize: 15, height: 1.5),
        ),
      ];
    }
    final bubbles = <Widget>[];
    String? lastDay;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final date = DateTime.tryParse(entry.createdAt ?? '')?.toLocal();
      if (date != null) {
        final day = '${date.year}-${date.month}-${date.day}';
        if (day != lastDay) {
          bubbles.add(
            _DayChip(label: formatJalali(entry.createdAt, withTime: false)),
          );
          lastDay = day;
        }
      }
      final previous = i == 0 ? null : entries[i - 1];
      final next = i + 1 < entries.length ? entries[i + 1] : null;
      final groupStart = previous == null || previous.sender != entry.sender;
      if (!entry.mine && groupStart && entry.name.isNotEmpty) {
        bubbles.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 18,
              top: 8,
              bottom: 2,
            ),
            child: Text(
              entry.name,
              style: TextStyle(
                color: dt.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      bubbles.add(
        BubbleNormal(
          text: entry.text,
          isSender: entry.mine,
          tail: next == null || next.sender != entry.sender,
          color: entry.mine ? dt.primary : dt.surface,
          textStyle: TextStyle(
            color: entry.mine ? dt.onPrimary : dt.text,
            fontSize: 15,
            height: 1.5,
          ),
          timestamp: entry.createdAt == null
              ? null
              : formatJalali(entry.createdAt, timeFirst: true),
        ),
      );
    }
    return bubbles;
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({
    required this.ticket,
    required this.canEdit,
    required this.onStatus,
  });

  final Ticket ticket;
  final bool canEdit;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final initial = ticket.customerName.trim().isEmpty
        ? '؟'
        : ticket.customerName.trim().characters.first;
    final chip = _StatusChip(status: ticket.status, chevron: canEdit);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'بازگشت',
            visualDensity: VisualDensity.compact,
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_forward,
              textDirection: TextDirection.ltr,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dt.primary50,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: TextStyle(color: dt.primary, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: dt.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (ticket.customerName.trim().isNotEmpty)
                      ticket.customerName.trim(),
                    faLabel(ticketPriorityLabels, ticket.priority),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: dt.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (canEdit)
            PopupMenuButton<String>(
              initialValue: ticket.status,
              onSelected: onStatus,
              itemBuilder: (context) => [
                for (final entry in ticketStatusLabels.entries)
                  if (entry.key != 'all')
                    PopupMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              child: chip,
            )
          else
            chip,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.chevron = false});

  final String status;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context.dt, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            faLabel(ticketStatusLabels, status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          if (chevron)
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: color),
        ],
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in ticketStatusLabels.entries)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _StatusFilterChip(
                label: entry.value,
                color: entry.key == 'all'
                    ? dt.textMuted
                    : _statusColor(dt, entry.key),
                selected: selected == entry.key,
                onTap: () => onSelected(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.16) : context.dt.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? color : context.dt.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : context.dt.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final color = _statusColor(dt, ticket.status);
    final name = ticket.customerName.trim();
    final initial = name.isEmpty ? '؟' : name.characters.first;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/dashboard/tickets/${ticket.id}'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 14, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (name.isNotEmpty) name,
                                faLabel(ticketPriorityLabels, ticket.priority),
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: dt.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: dt.textSubtle,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  faInt(ticket.commentCount),
                                  style: TextStyle(
                                    color: dt.textSubtle,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (ticket.updatedAt.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    formatJalali(
                                      ticket.updatedAt,
                                      withTime: false,
                                    ),
                                    style: TextStyle(
                                      color: dt.textSubtle,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(status: ticket.status),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: dt.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: dt.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Color _statusColor(DtColors dt, String status) {
  return switch (status) {
    'in_progress' => dt.warning,
    'resolved' => dt.success,
    'closed' => dt.textMuted,
    _ => dt.primary,
  };
}
