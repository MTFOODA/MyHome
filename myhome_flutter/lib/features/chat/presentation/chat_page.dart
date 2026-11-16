import '../../../core/widgets/app_layout.dart';
import '../../../core/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/chat_repository.dart';
import '../../sales/presentation/sales_strings.dart';
import 'chat_cubit.dart';

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
      builder: (context, state) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              salesText(context, 'chatPrivacy'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                salesText(context, state.error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    children: [
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
                              maxWidth: (AppLayout.width(context) * .76).clamp(
                                240,
                                760,
                              ),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: message.mine
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!message.mine)
                                  Text(
                                    message.alias,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                Text(message.text),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.viewInsetsOf(context).bottom > 0 ? 8 : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chatInput'),
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: salesText(context, 'messageHint'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('sendMessage'),
                    onPressed: state.loading || state.sending ? null : _send,
                    icon: state.sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const AppIcon(Icons.send),
                    tooltip: salesText(context, 'sendMessage'),
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
