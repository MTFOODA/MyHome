import '../../../core/widgets/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/chat_repository.dart';
import '../../sales/presentation/sales_strings.dart';
import 'chat_cubit.dart';
import 'conversation_list.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/config/price_text.dart';
import '../../properties/domain/property_repository.dart';
import '../../properties/presentation/property_details_page.dart';
import '../../properties/presentation/property_photo.dart';

class ChatPage extends StatefulWidget {
  final String? dealId, groupId, propertyId, seekerId, conversationId;
  const ChatPage({
    super.key,
    this.dealId,
    this.groupId,
    this.propertyId,
    this.seekerId,
    this.conversationId,
  }) : assert(
         (dealId != null ? 1 : 0) +
                 (groupId != null ? 1 : 0) +
                 (propertyId != null ? 1 : 0) +
                 (conversationId != null ? 1 : 0) ==
             1,
       );
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatCubit _cubit;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _quickOpen = false;
  @override
  void initState() {
    super.initState();
    _cubit = ChatCubit(
      context.read<ChatRepository>(),
      dealId: widget.dealId,
      groupId: widget.groupId,
      propertyId: widget.propertyId,
      seekerId: widget.seekerId,
      conversationId: widget.conversationId,
    )..open();
  }

  @override
  void dispose() {
    _cubit.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text;
    if (await _cubit.send(text)) {
      if (mounted && _input.text == text) _input.clear();
    }
  }

  Widget _thread(BuildContext context, ChatState state) {
    final colors = Theme.of(context).colorScheme;
    final metadata = _cubit.contextData;
    final name = '${metadata['name'] ?? ''}';
    final property = metadata['property'] as Map?;
    final wide = AppLayout.width(context) >= 1000;
    return ColoredBox(
      color: colors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  child: name.isEmpty
                      ? const Icon(Icons.chat_bubble_outline)
                      : Text(name.characters.take(1).toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name.isEmpty ? salesText(context, 'chat') : name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (metadata['owner_verified'] == true)
                  Icon(
                    Icons.verified_outlined,
                    color: colors.primary,
                    semanticLabel: words(context, 'approved'),
                  ),
              ],
            ),
          ),
          if (property != null)
            Material(
              color: colors.surfaceContainerLow,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PropertyDetailsPage(
                      id: '${property['id']}',
                      repository: context.read<PropertyRepository>(),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 76,
                          height: 68,
                          child: PropertyPhoto(
                            id: property['cover_id'] as String?,
                            category: '${property['category']}',
                            repository: context.read<PropertyRepository>(),
                            private: property['cover_private'] == true,
                            compact: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              words(context, 'discussingProperty'),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.primary),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${property['title']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${priceText('${property['price']}')} ${Localizations.localeOf(context).languageCode == 'ar' ? 'ج.م' : 'EGP'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      salesText(context, state.error!),
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                  if (_cubit.id == null)
                    IconButton(
                      onPressed: _cubit.open,
                      icon: const Icon(Icons.refresh),
                      tooltip: words(context, 'retry'),
                    ),
                ],
              ),
            ),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, box) => ListView(
                      controller: _scroll,
                      padding: EdgeInsets.symmetric(
                        horizontal: wide ? 30 : 16,
                        vertical: 22,
                      ),
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            margin: const EdgeInsets.only(bottom: 22),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer.withValues(
                                alpha: .45,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  color: colors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    words(context, 'chatSafety'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (state.before != null)
                          TextButton(
                            onPressed: state.olderLoading ? null : _cubit.older,
                            child: Text(salesText(context, 'olderMessages')),
                          ),
                        if (state.messages.isEmpty)
                          Center(child: Text(salesText(context, 'empty'))),
                        for (final message in state.messages)
                          Align(
                            alignment: message.mine
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: (box.maxWidth * .8).clamp(0, 680),
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: message.mine
                                    ? colors.primary
                                    : colors.surfaceContainerLow,
                                border: Border.all(
                                  color: message.mine
                                      ? colors.primary
                                      : colors.outlineVariant,
                                ),
                                borderRadius: BorderRadiusDirectional.only(
                                  topStart: const Radius.circular(20),
                                  topEnd: const Radius.circular(20),
                                  bottomStart: Radius.circular(
                                    message.mine ? 20 : 4,
                                  ),
                                  bottomEnd: Radius.circular(
                                    message.mine ? 4 : 20,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!message.mine &&
                                      metadata['kind'] == 'group')
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        message.alias,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ),
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      color: message.mine
                                          ? colors.onPrimary
                                          : colors.onSurface,
                                      height: 1.5,
                                    ),
                                  ),
                                  if (message.createdAt case final time?) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      MaterialLocalizations.of(
                                        context,
                                      ).formatTimeOfDay(
                                        TimeOfDay.fromDateTime(time.toLocal()),
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: message.mine
                                                ? colors.onPrimary.withValues(
                                                    alpha: .8,
                                                  )
                                                : colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () => setState(() => _quickOpen = !_quickOpen),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_outlined, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              words(context, 'quickMessages'),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          Icon(
                            _quickOpen ? Icons.expand_less : Icons.expand_more,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_quickOpen)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LayoutBuilder(
                        builder: (context, box) => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final key in [
                              'quickViewing',
                              'quickPrice',
                              'quickPhotos',
                              'quickFees',
                            ])
                              SizedBox(
                                width: wide ? null : (box.maxWidth - 8) / 2,
                                child: OutlinedButton(
                                  key: ValueKey(key),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 58),
                                    padding: const EdgeInsets.all(10),
                                  ),
                                  child: Text(
                                    words(context, key),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                  ),
                                  onPressed: () {
                                    _input.text = words(context, key);
                                    _input.selection = TextSelection.collapsed(
                                      offset: _input.text.length,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('chatInput'),
                          controller: _input,
                          onTap: () {
                            if (_quickOpen && !wide) {
                              setState(() => _quickOpen = false);
                            }
                          },
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (!state.loading && !state.sending) _send();
                          },
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: salesText(context, 'messageHint'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        key: const Key('sendMessage'),
                        onPressed: state.loading || state.sending
                            ? null
                            : _send,
                        icon: state.sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.send_outlined,
                                color: state.loading ? null : colors.onPrimary,
                              ),
                        tooltip: salesText(context, 'sendMessage'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    salesText(context, 'chatPrivacy'),
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(title: Text(salesText(context, 'chat'))),
    body: BlocConsumer<ChatCubit, ChatState>(
      bloc: _cubit,
      listenWhen: (previous, current) =>
          previous.messages.lastOrNull?.id != current.messages.lastOrNull?.id,
      listener: (context, state) {
        if (state.messages.isNotEmpty &&
            (!_scroll.hasClients ||
                _scroll.position.extentAfter < 100 ||
                state.messages.last.mine)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scroll.hasClients) {
              if (MediaQuery.disableAnimationsOf(context)) {
                _scroll.jumpTo(_scroll.position.maxScrollExtent);
              } else {
                _scroll.animateTo(
                  _scroll.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            }
          });
        }
      },
      builder: (context, state) => LayoutBuilder(
        builder: (context, box) {
          final thread = _thread(context, state);
          if (box.maxWidth < 1000 ||
              widget.groupId != null ||
              widget.dealId != null) {
            return thread;
          }
          return Row(
            children: [
              SizedBox(
                width: 340,
                child: ConversationList(
                  selected: _cubit.id,
                  onSelected: (id) {
                    if (id != _cubit.id) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ChatPage(conversationId: id),
                        ),
                      );
                    }
                  },
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(child: thread),
            ],
          );
        },
      ),
    ),
  );
}
