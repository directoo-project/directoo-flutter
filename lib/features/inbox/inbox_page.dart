import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_exception.dart';
import '../../core/format.dart';
import '../../domain/repositories/inbox_repository.dart';
import '../../domain/entities/models.dart';
import '../../presentation/session/session_bloc.dart';
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
    final id = context.read<SessionBloc>().workspaceId;
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
      final page = await context.read<InboxRepository>().directChats(id);
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
    if (_loading && _items.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: 'صندوق ورودی', description: 'دایرکت‌های اینستاگرام'),
          Expanded(child: _InboxSkeleton()),
        ],
      );
    }
    final dt = context.dt;
    return Column(
      children: [
        const PageHeader(title: 'صندوق ورودی', description: 'دایرکت‌های اینستاگرام'),
        Expanded(
          child: _error != null
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: InkWell(
                              onTap: () => context.push('/dashboard/inbox/chat?id=${Uri.encodeQueryComponent(chat.chatId)}'),
                              child: Row(
                                children: [
                                  _PeerAvatar(name: chat.title),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(chat.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 2),
                                        Text(chat.preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: dt.textMuted, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(formatJalali(chat.time, withTime: false), style: TextStyle(fontSize: 11, color: dt.textSubtle)),
                                ],
                              ),
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
  String? _sendError;

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

  Future<void> _load({bool silent = false}) async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final page = await context.read<InboxRepository>().directMessages(id, widget.chatId);
      if (mounted) {
        setState(() {
          _items = page.items;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && _items.isEmpty) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final id = context.read<SessionBloc>().workspaceId;
    final text = _text.text.trim();
    if (id == null || text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      await context.read<InboxRepository>().sendDirect(id, widget.chatId, text);
      _text.clear();
      await _load(silent: true);
    } catch (error) {
      if (mounted) setState(() => _sendError = errorText(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    return Column(
      children: [
        const PageHeader(title: 'گفتگوها', description: 'پیام‌های این گفتگو'),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const _ThreadSkeleton()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : ListView.builder(
                      controller: _scroll,
                      itemCount: _items.length + (_sendError == null ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (_sendError != null && index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(_sendError!, textAlign: TextAlign.center, style: TextStyle(color: dt.error, fontWeight: FontWeight.w600)),
                          );
                        }
                        final message = _items[_sendError == null ? index : index - 1];
                        return _MessageBubble(message: message);
                      },
                    ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'پیام',
                  filled: true,
                  fillColor: dt.surfaceMuted,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: dt.primary)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _sending ? dt.primary.withValues(alpha: 0.45) : dt.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending ? null : _send,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: Icon(Icons.send_rounded, color: dt.onPrimary, size: 20),
                  ),
                ),
              ),
            ),
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
    final id = context.read<SessionBloc>().workspaceId;
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
      final page = await context.read<InboxRepository>().comments(id);
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
          const Text('پاسخ به کامنت', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(controller: controller, minLines: 3, maxLines: 6, decoration: const InputDecoration(hintText: 'متن پاسخ')),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('ارسال')),
        ],
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    try {
      await context.read<InboxRepository>().replyComment(id, commentId: comment.commentId, text: text, mediaId: comment.mediaId);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canReply = context.watch<SessionBloc>().permissions.canReply;
    if (_loading && _items.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: 'صندوق کامنت', description: 'کامنت‌های اینستاگرام و پاسخ مستقیم'),
          Expanded(child: _InboxSkeleton()),
        ],
      );
    }
    final dt = context.dt;
    return Column(
      children: [
        const PageHeader(title: 'صندوق کامنت', description: 'کامنت‌های اینستاگرام و پاسخ مستقیم'),
        Expanded(
          child: _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const EmptyView(title: 'کامنتی نیست')
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final comment = _items[index];
                        final handle = comment.username.isEmpty ? 'کاربر' : '@${comment.username}';
                        return SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(handle, textDirection: comment.username.isEmpty ? null : TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(comment.text.isEmpty ? 'بدون متن' : comment.text, style: TextStyle(color: dt.text, height: 1.5)),
                              const SizedBox(height: 6),
                              Text(formatJalali(comment.createdAt, timeFirst: true), style: TextStyle(color: dt.textSubtle, fontSize: 12)),
                              if (canReply && comment.direction != 'outbound')
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: TextButton(
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                    onPressed: () => _reply(comment),
                                    child: const Text('پاسخ'),
                                  ),
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

class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    const palette = [Color(0xFF2D4BFF), Color(0xFFFF5C39), Color(0xFF16A34A), Color(0xFF7C6AF7), Color(0xFF0EA5E9)];
    final letter = name.replaceAll('@', '').trim();
    final glyph = letter.isEmpty ? '?' : letter.characters.first;
    final color = palette[name.hashCode.abs() % palette.length];
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
      child: Text(glyph, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }
}

class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SkeletonBox(width: 140, height: 22, radius: 8),
        SizedBox(height: 8),
        SkeletonBox(width: 180, height: 12, radius: 8),
        SizedBox(height: 16),
        SkeletonBox(height: 72, radius: 16),
        SizedBox(height: 8),
        SkeletonBox(height: 72, radius: 16),
        SizedBox(height: 8),
        SkeletonBox(height: 72, radius: 16),
        SizedBox(height: 8),
        SkeletonBox(height: 72, radius: 16),
        SizedBox(height: 8),
        SkeletonBox(height: 72, radius: 16),
        SizedBox(height: 8),
        SkeletonBox(height: 72, radius: 16),
      ],
    );
  }
}

class _ThreadSkeleton extends StatelessWidget {
  const _ThreadSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBox(width: 180, height: 42, radius: 16)),
        SizedBox(height: 10),
        Align(alignment: AlignmentDirectional.centerEnd, child: SkeletonBox(width: 150, height: 42, radius: 16)),
        SizedBox(height: 10),
        Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBox(width: 210, height: 64, radius: 16)),
        SizedBox(height: 10),
        Align(alignment: AlignmentDirectional.centerEnd, child: SkeletonBox(width: 120, height: 36, radius: 16)),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final DirectMessage message;

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;
    final mine = message.outbound;
    final hasImage = message.imageUrl.isNotEmpty;
    final bubble = hasImage
        ? Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: dt.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: dt.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl,
                    height: 160,
                    width: 200,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      height: 160,
                      width: 200,
                      color: dt.surfaceMuted,
                      child: Icon(Icons.image_outlined, color: dt.textSubtle, size: 32),
                    ),
                  ),
                ),
                if (message.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(message.text, style: TextStyle(color: dt.text, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? dt.primary : dt.surface,
              borderRadius: BorderRadius.circular(18),
              border: mine ? null : Border.all(color: dt.border),
            ),
            child: Text(message.text, style: TextStyle(color: mine ? dt.onPrimary : dt.text, height: 1.5, fontWeight: FontWeight.w600)),
          );
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        child: bubble,
      ),
    );
  }
}
