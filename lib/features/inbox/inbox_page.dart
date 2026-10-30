import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../data/directoo_api.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  List<DirectChat> _items = const [];
  var _loading = true;
  String? _error;
  int? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<SessionController>().workspaceId;
    if (id != null && id != _loadedFor) {
      _loadedFor = id;
      _load();
    }
  }

  Future<void> _load() async {
    final id = _loadedFor;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final page = await context.read<DirectooApi>().directChats(id);
      if (mounted) {
        setState(() {
          _items = page.items;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader(title: 'صندوق ورودی', description: 'دایرکت‌های اینستاگرام'),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? const EmptyView(title: 'گفتگویی نیست', subtitle: 'بعد از اتصال اینستاگرام، دایرکت‌ها اینجا می‌آیند.')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final chat = _items[index];
                              return SurfaceCard(
                                padding: EdgeInsets.zero,
                                child: ListTile(
                                  title: Text(chat.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  subtitle: Text(chat.preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: Text(formatJalali(chat.time, withTime: false), style: TextStyle(fontSize: 11, color: context.dt.textSubtle)),
                                  onTap: () => context.push('/dashboard/inbox/chat?id=${Uri.encodeQueryComponent(chat.chatId)}'),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class InboxThreadPage extends StatefulWidget {
  const InboxThreadPage({super.key, required this.chatId});

  final String chatId;

  @override
  State<InboxThreadPage> createState() => _InboxThreadPageState();
}

class _InboxThreadPageState extends State<InboxThreadPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<DirectMessage> _items = const [];
  var _loading = true;
  var _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final page = await context.read<DirectooApi>().directMessages(id, widget.chatId);
      if (mounted) setState(() => _items = page.items);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final id = context.read<SessionController>().workspaceId;
    final text = _text.text.trim();
    if (id == null || text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await context.read<DirectooApi>().sendDirect(id, widget.chatId, text);
      _text.clear();
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    if (_loading) return const LoadingView();
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_forward), label: const Text('گفتگوها')),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: dt.error)),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final message = _items[index];
              final mine = message.outbound;
              return Align(
                alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: mine ? dt.primary : dt.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(imageUrl: message.imageUrl, height: 140, fit: BoxFit.cover),
                        ),
                      if (message.text.isNotEmpty)
                        Text(message.text, style: TextStyle(color: mine ? dt.onPrimary : dt.text)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          children: [
            Expanded(child: TextField(controller: _text, decoration: const InputDecoration(hintText: 'پیام'))),
            const SizedBox(width: 8),
            FilledButton(onPressed: _sending ? null : _send, child: const Text('ارسال')),
          ],
        ),
      ],
    );
  }
}

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  List<IgComment> _items = const [];
  var _loading = true;
  String? _error;
  int? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<SessionController>().workspaceId;
    if (id != null && id != _loadedFor) {
      _loadedFor = id;
      _load();
    }
  }

  Future<void> _load() async {
    final id = _loadedFor;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final page = await context.read<DirectooApi>().comments(id);
      if (mounted) {
        setState(() {
          _items = page.items;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reply(IgComment comment) async {
    final controller = TextEditingController();
    final text = await showFormSheet<String>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: 'پاسخ به کامنت'),
          TextField(controller: controller, minLines: 3, maxLines: 6, decoration: const InputDecoration(hintText: 'متن پاسخ')),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('ارسال')),
        ],
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final id = context.read<SessionController>().workspaceId;
    if (id == null) return;
    try {
      await context.read<DirectooApi>().replyComment(id, commentId: comment.commentId, text: text, mediaId: comment.mediaId);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canReply = context.watch<SessionController>().permissions.canReply;
    return Column(
      children: [
        const PageHeader(title: 'صندوق کامنت', description: 'کامنت‌های اینستاگرام و پاسخ مستقیم'),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? const EmptyView(title: 'کامنتی نیست')
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final comment = _items[index];
                            return SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment.username.isEmpty ? 'کاربر' : '@${comment.username}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(comment.text.isEmpty ? 'بدون متن' : comment.text),
                                  Text(formatJalali(comment.createdAt), style: TextStyle(color: context.dt.textSubtle, fontSize: 12)),
                                  if (canReply && comment.direction != 'outbound')
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(onPressed: () => _reply(comment), child: const Text('پاسخ')),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
