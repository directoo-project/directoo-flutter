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
      final items = await context.read<TicketsRepository>().tickets(id, status: _status, search: _search.text.trim());
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
            const PageHeader(title: 'تیکت جدید', description: 'موضوع و شرح درخواست را بنویسید'),
            TextField(controller: subject, decoration: const InputDecoration(labelText: 'موضوع')),
            const SizedBox(height: 12),
            TextField(controller: description, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'شرح')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'اولویت'),
              items: [for (final entry in ticketPriorityLabels.entries) if (entry.key != 'all') DropdownMenuItem(value: entry.key, child: Text(entry.value))],
              onChanged: (value) => setLocal(() => priority = value ?? 'medium'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ثبت')),
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
          action: canEdit ? IconButton(onPressed: _create, icon: const Icon(Icons.add)) : null,
        ),
        TextField(
          controller: _search,
          decoration: InputDecoration(hintText: 'جستجو', suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.search))),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 12),
        FilterChips(options: ticketStatusLabels, selected: _status, onSelected: (value) {
          setState(() => _status = value);
          _load();
        }),
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
                          itemBuilder: (context, index) {
                            final ticket = _items[index];
                            return SurfaceCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.w800)),
                                subtitle: Text('${faLabel(ticketStatusLabels, ticket.status)} · ${faLabel(ticketPriorityLabels, ticket.priority)}'),
                                trailing: Text(faInt(ticket.commentCount)),
                                onTap: () => context.push('/dashboard/tickets/${ticket.id}'),
                              ),
                            );
                          },
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
  final _comment = TextEditingController();
  Ticket? _ticket;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final workspaceId = context.read<SessionBloc>().workspaceId;
    if (workspaceId == null) return;
    setState(() => _loading = true);
    try {
      final ticket = await context.read<TicketsRepository>().ticket(workspaceId, widget.id);
      if (mounted) setState(() => _ticket = ticket);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final workspaceId = context.read<SessionBloc>().workspaceId;
    final text = _comment.text.trim();
    if (workspaceId == null || text.isEmpty) return;
    try {
      await context.read<TicketsRepository>().addTicketComment(workspaceId, widget.id, text);
      _comment.clear();
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
      final updated = await context.read<TicketsRepository>().saveTicket(workspaceId, {'status': status}, ticketId: ticket.id);
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
          Expanded(child: ErrorView(message: _error!, onRetry: _load)),
        ],
      );
    }
    final ticket = _ticket!;
    final canEdit = context.watch<SessionBloc>().permissions.canEditTickets;
    return Column(
      children: [
        PageHeader(title: ticket.subject, description: '${faLabel(ticketStatusLabels, ticket.status)} · ${ticket.customerName}'),
        if (canEdit)
          DropdownButtonFormField<String>(
            initialValue: ticket.status,
            items: [for (final entry in ticketStatusLabels.entries) if (entry.key != 'all') DropdownMenuItem(value: entry.key, child: Text(entry.value))],
            onChanged: (value) {
              if (value != null) _setStatus(value);
            },
          ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              SurfaceCard(child: Text(ticket.description.isEmpty ? 'بدون شرح' : ticket.description)),
              const SizedBox(height: 12),
              for (final comment in ticket.comments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(comment.content),
                        Text(formatJalali(comment.createdAt), style: TextStyle(color: context.dt.textSubtle, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: context.dt.error)),
        Row(
          children: [
            Expanded(child: TextField(controller: _comment, decoration: const InputDecoration(hintText: 'پاسخ'))),
            const SizedBox(width: 8),
            FilledButton(onPressed: _send, child: const Text('ارسال')),
          ],
        ),
      ],
    );
  }
}
