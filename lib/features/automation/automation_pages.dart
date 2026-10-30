import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_exception.dart';
import '../../core/json.dart';
import '../../core/labels.dart';
import '../../domain/repositories/automation_repository.dart';
import '../../domain/entities/models.dart';
import '../../presentation/session/session_bloc.dart';
import '../../widgets/ui.dart';

class AutomationListPage extends StatefulWidget {
  const AutomationListPage({
    super.key,
    required this.title,
    required this.description,
    required this.triggerType,
  });

  final String title;
  final String description;
  final String triggerType;

  @override
  State<AutomationListPage> createState() => _AutomationListPageState();
}

class _AutomationListPageState extends State<AutomationListPage> {
  List<AutomationFlow> _items = const [];
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
      final items = await context.read<AutomationRepository>().automations(id, widget.triggerType);
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

  Future<void> _toggle(AutomationFlow flow) async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    final next = flow.status == 'active' ? 'inactive' : 'active';
    await context.read<AutomationRepository>().saveAutomation(id, {'status': next}, flowId: flow.id);
    await _load();
  }

  Future<void> _openEditor([int? flowId]) async {
    final saved = await showFormSheet<bool>(
      context,
      builder: (_) => AutomationEditorPage(triggerType: widget.triggerType, flowId: flowId),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(AutomationFlow flow) async {
    final id = context.read<SessionBloc>().workspaceId;
    final api = context.read<AutomationRepository>();
    if (id == null || !await confirmDelete(context, 'حذف این اتوماسیون؟')) return;
    if (!mounted) return;
    await api.deleteAutomation(id, flow.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<SessionBloc>().permissions.canManageAutomation;
    return Column(
      children: [
        PageHeader(
          title: widget.title,
          description: widget.description,
          action: canEdit ? IconButton(onPressed: () => _openEditor(), icon: const Icon(Icons.add)) : null,
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _items.isEmpty
                      ? const EmptyView(title: 'موردی ساخته نشده')
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final flow = _items[index];
                            final keywords = asStringList(flow.trigger['keywords']);
                            return SurfaceCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(flow.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                        Text(keywords.isEmpty ? faLabel(automationStatusLabels, flow.status) : keywords.join('، ')),
                                      ],
                                    ),
                                  ),
                                  if (canEdit) ...[
                                    IconButton(onPressed: () => _openEditor(flow.id), icon: const Icon(Icons.edit_outlined)),
                                    IconButton(onPressed: () => _toggle(flow), icon: Icon(flow.status == 'active' ? Icons.pause : Icons.play_arrow_outlined)),
                                    IconButton(onPressed: () => _delete(flow), icon: const Icon(Icons.delete_outline)),
                                  ],
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

class AutomationEditorPage extends StatefulWidget {
  const AutomationEditorPage({super.key, required this.triggerType, this.flowId});

  final String triggerType;
  final int? flowId;

  @override
  State<AutomationEditorPage> createState() => _AutomationEditorPageState();
}

class _AutomationEditorPageState extends State<AutomationEditorPage> {
  final _name = TextEditingController();
  final _keywords = TextEditingController();
  final _message = TextEditingController();
  final _comment = TextEditingController();
  final _delay = TextEditingController(text: '120');
  final _cardTitle = TextEditingController();
  final _cardBody = TextEditingController();
  final _cardUrl = TextEditingController();
  var _match = 'equals';
  var _source = 'post';
  var _channel = 'direct';
  var _status = 'active';
  var _loading = false;
  var _booting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.flowId != null) {
      _booting = true;
      _load();
    }
  }

  Future<void> _load() async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    try {
      final flows = await context.read<AutomationRepository>().automations(id, widget.triggerType);
      final flow = flows.where((item) => item.id == widget.flowId).firstOrNull;
      if (flow != null) {
        _name.text = flow.name;
        _status = flow.status.isEmpty ? 'active' : flow.status;
        _match = asString(flow.trigger['match']).isEmpty ? 'equals' : asString(flow.trigger['match']);
        _source = asString(flow.trigger['source']).isEmpty ? 'post' : asString(flow.trigger['source']);
        _channel = asString(flow.trigger['reply_channel']).isEmpty ? 'direct' : asString(flow.trigger['reply_channel']);
        _keywords.text = asStringList(flow.trigger['keywords']).join(', ');
        _comment.text = asString(flow.trigger['comment_text']);
        final step = flow.steps.isEmpty ? <String, dynamic>{} : flow.steps.first;
        final config = asJson(step['config']);
        _message.text = asString(config['text']);
        _cardTitle.text = asString(config['title']);
        _cardBody.text = asString(config['description']);
        _cardUrl.text = asString(config['url']);
        if (config['delay_minutes'] != null) _delay.text = asInt(config['delay_minutes']).toString();
      }
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _booting = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _keywords, _message, _comment, _delay, _cardTitle, _cardBody, _cardUrl]) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _keywordList => _keywords.text.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

  Json _payload() {
    final keywords = widget.triggerType == 'comment' && _match == 'any' ? <String>[] : _keywordList;
    final trigger = <String, dynamic>{
      'type': widget.triggerType,
      'value': keywords.isEmpty ? '' : keywords.first,
      'match': widget.triggerType == 'follow_up' ? 'equals' : _match,
      'keywords': keywords,
    };
    if (widget.triggerType == 'comment') {
      trigger.addAll({
        'source': _source,
        'reply_channel': _channel,
        'comment_text': _channel == 'both' ? _comment.text.trim() : '',
      });
    }
    if (widget.triggerType == 'smart_reply' || widget.triggerType == 'vitrin') {
      trigger['like_command'] = false;
    }
    final steps = <Json>[];
    if (widget.triggerType == 'vitrin') {
      steps.add({
        'id': 'card-1',
        'type': 'action',
        'label': 'card',
        'config': {
          'kind': 'card',
          'text': '',
          'url': _cardUrl.text.trim(),
          'title': _cardTitle.text.trim(),
          'description': _cardBody.text.trim(),
          'buttons': <Json>[],
        },
      });
    } else if (widget.triggerType == 'follow_up') {
      steps.add({
        'id': 'follow-1',
        'type': 'action',
        'label': 'text',
        'config': {
          'kind': 'text',
          'text': _message.text.trim(),
          'url': '',
          'delay_minutes': int.tryParse(_delay.text) ?? 120,
          'buttons': <Json>[],
        },
      });
    } else {
      steps.add({
        'id': 'msg-1',
        'type': 'action',
        'label': 'text',
        'config': {
          'kind': 'text',
          'text': _message.text.trim(),
          'url': '',
          'channel': _channel == 'comment' ? 'comment' : 'direct',
          'buttons': <Json>[],
        },
      });
    }
    return {
      'name': _name.text.trim().isEmpty ? (keywords.isEmpty ? 'اتوماسیون جدید' : keywords.first) : _name.text.trim(),
      'description': widget.triggerType,
      'status': _status,
      'trigger': trigger,
      'steps': steps,
    };
  }

  Future<void> _save() async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    if (_keywordList.isEmpty && !(widget.triggerType == 'comment' && _match == 'any')) {
      setState(() => _error = 'حداقل یک کلمه کلیدی وارد کنید.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AutomationRepository>().saveAutomation(id, _payload(), flowId: widget.flowId);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return FormSheetScope.isSheet(context) ? const SizedBox(height: 160, child: LoadingView()) : const LoadingView();
    }
    return formBody(context, [
        PageHeader(title: widget.flowId == null ? 'مورد جدید' : 'ویرایش'),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'نام')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'وضعیت'),
          items: [for (final entry in automationStatusLabels.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value))],
          onChanged: (value) => setState(() => _status = value ?? 'active'),
        ),
        if (widget.triggerType == 'comment') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _source,
            decoration: const InputDecoration(labelText: 'منبع'),
            items: [for (final entry in commentSourceLabels.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value))],
            onChanged: (value) => setState(() => _source = value ?? 'post'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _channel,
            decoration: const InputDecoration(labelText: 'کانال پاسخ'),
            items: [for (final entry in replyChannelLabels.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value))],
            onChanged: (value) => setState(() => _channel = value ?? 'direct'),
          ),
        ],
        if (widget.triggerType != 'follow_up') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _match,
            decoration: const InputDecoration(labelText: 'نوع تطبیق'),
            items: [
              for (final entry in commentMatchLabels.entries)
                if (widget.triggerType == 'comment' || entry.key == 'equals' || entry.key == 'contains')
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) => setState(() => _match = value ?? 'equals'),
          ),
        ],
        const SizedBox(height: 12),
        TextField(controller: _keywords, decoration: const InputDecoration(labelText: 'کلمه‌های کلیدی، با ویرگول')),
        const SizedBox(height: 12),
        if (widget.triggerType == 'vitrin') ...[
          TextField(controller: _cardTitle, decoration: const InputDecoration(labelText: 'عنوان کارت')),
          const SizedBox(height: 12),
          TextField(controller: _cardBody, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'توضیح کارت')),
          const SizedBox(height: 12),
          TextField(controller: _cardUrl, decoration: const InputDecoration(labelText: 'تصویر یا لینک')),
        ] else ...[
          TextField(controller: _message, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'متن پاسخ')),
        ],
        if (widget.triggerType == 'follow_up') ...[
          const SizedBox(height: 12),
          TextField(controller: _delay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'تأخیر (دقیقه)')),
        ],
        if (widget.triggerType == 'comment' && _channel == 'both') ...[
          const SizedBox(height: 12),
          TextField(controller: _comment, decoration: const InputDecoration(labelText: 'متن پاسخ عمومی کامنت')),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!),
        ],
        const SizedBox(height: 16),
        FilledButton(onPressed: _loading ? null : _save, child: Text(_loading ? 'در حال ذخیره...' : 'ذخیره')),
      ],
    );
  }
}

class IceBreakersPage extends StatefulWidget {
  const IceBreakersPage({super.key});

  @override
  State<IceBreakersPage> createState() => _IceBreakersPageState();
}

class _IceBreakersPageState extends State<IceBreakersPage> {
  final _welcome = TextEditingController();
  final _questions = List.generate(4, (_) => TextEditingController());
  final _replies = List.generate(4, (_) => TextEditingController());
  int? _flowId;
  var _active = true;
  var _loading = true;
  var _saving = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _welcome.dispose();
    for (final controller in [..._questions, ..._replies]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    try {
      final flows = await context.read<AutomationRepository>().automations(id, 'ice_breaker');
      if (flows.isNotEmpty) {
        final flow = flows.first;
        _flowId = flow.id;
        _active = flow.status != 'inactive';
        for (final step in flow.steps) {
          final config = asJson(step['config']);
          if (config['kind'] == 'welcome' || step['label'] == 'welcome') {
            _welcome.text = asString(config['text']);
          }
        }
        final items = flow.steps.where((step) {
          final config = asJson(step['config']);
          return config['kind'] == 'ice_breaker' || step['label'] == 'ice_breaker';
        }).toList();
        for (var i = 0; i < items.length && i < 4; i++) {
          final config = asJson(items[i]['config']);
          _questions[i].text = asString(config['question']);
          _replies[i].text = asString(config['text']);
        }
      }
    } catch (error) {
      _error = errorText(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final id = context.read<SessionBloc>().workspaceId;
    if (id == null) return;
    setState(() => _saving = true);
    final steps = <Json>[
      {
        'id': 'welcome',
        'type': 'action',
        'label': 'welcome',
        'config': {'kind': 'welcome', 'text': _welcome.text.trim()},
      },
      for (var i = 0; i < 4; i++)
        if (_questions[i].text.trim().isNotEmpty)
          {
            'id': 'ice-$i',
            'type': 'action',
            'label': 'ice_breaker',
            'config': {
              'kind': 'ice_breaker',
              'question': _questions[i].text.trim(),
              'text': _replies[i].text.trim(),
              'title': _questions[i].text.trim(),
              'payload': 'ice_breaker_$i',
            },
          },
    ];
    try {
      final saved = await context.read<AutomationRepository>().saveAutomation(id, {
        'name': 'پیام خوش‌آمدگویی',
        'description': 'پیام خوش‌آمدگویی و میانبرهای شروع مکالمه دایرکت',
        'status': _active ? 'active' : 'inactive',
        'trigger': {'type': 'ice_breaker', 'value': 'welcome', 'match': 'any', 'keywords': <String>[]},
        'steps': steps,
      }, flowId: _flowId);
      _flowId = saved.id;
      if (mounted) setState(() => _message = 'پیام خوش‌آمدگویی ذخیره شد.');
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: 'پیام خوش‌آمدگویی', description: 'متن خوش‌آمد و حداکثر ۴ میانبر شروع مکالمه'),
          Expanded(child: LoadingView()),
        ],
      );
    }
    return ListView(
      children: [
        const PageHeader(title: 'پیام خوش‌آمدگویی', description: 'متن خوش‌آمد و حداکثر ۴ میانبر شروع مکالمه'),
        if (_message != null) NoticeBanner(message: _message!),
        if (_error != null) NoticeBanner(message: _error!, error: true),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('فعال'), value: _active, onChanged: (value) => setState(() => _active = value)),
        TextField(controller: _welcome, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'متن خوش‌آمد')),
        for (var i = 0; i < 4; i++) ...[
          const SizedBox(height: 12),
          Text('میانبر ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
          TextField(controller: _questions[i], decoration: const InputDecoration(labelText: 'سؤال')),
          TextField(controller: _replies[i], decoration: const InputDecoration(labelText: 'پاسخ')),
        ],
        const SizedBox(height: 16),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'در حال ذخیره...' : 'ذخیره')),
      ],
    );
  }
}
