import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/marketplace_strings.dart';
import '../../../core/widgets/app_layout.dart';
import '../domain/chat_repository.dart';
import '../../properties/domain/property_repository.dart';
import 'chat_page.dart';
import 'conversation_list.dart';

class ContactsState {
  final List<Map<String, dynamic>> items;
  final String? cursor;
  final bool loading, failed;
  const ContactsState({
    this.items = const [],
    this.cursor,
    this.loading = false,
    this.failed = false,
  });
}

class ContactsCubit extends Cubit<ContactsState> {
  final Future<Map<String, dynamic>> Function(String?) fetch;
  ContactsCubit(this.fetch) : super(const ContactsState());
  Future<void> load({bool refresh = false}) async {
    if (state.loading) return;
    final old = refresh ? const ContactsState() : state;
    emit(ContactsState(items: old.items, cursor: old.cursor, loading: true));
    try {
      final page = await fetch(old.cursor);
      final items = <String, Map<String, dynamic>>{
        for (final v in old.items) v['id'] as String: v,
      };
      for (final v in page['items'] as List) {
        final item = Map<String, dynamic>.from(v as Map);
        items[item['id'] as String] = item;
      }
      if (!isClosed) {
        emit(
          ContactsState(
            items: items.values.toList(),
            cursor: page['next_cursor'] as String?,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(ContactsState(items: old.items, cursor: old.cursor, failed: true));
      }
    }
  }
}

/// Only owner-authorized names reach this list; no visitor identities or contact details.
class ContactListPage extends StatefulWidget {
  final String? propertyId;
  const ContactListPage({super.key, this.propertyId});
  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  late final ContactsCubit _cubit;
  @override
  void initState() {
    super.initState();
    _cubit = ContactsCubit(
      (before) => widget.propertyId != null
          ? context.read<PropertyRepository>().interested(
              widget.propertyId!,
              before: before,
            )
          : context.read<ChatRepository>().inbox(before: before),
    );
    if (widget.propertyId != null) _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: Text(
        words(
          context,
          widget.propertyId == null ? 'propertyMessages' : 'interestedPeople',
        ),
      ),
    ),
    body: widget.propertyId == null
        ? LayoutBuilder(
            builder: (context, box) {
              final list = ConversationList(
                onSelected: (id) => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ChatPage(conversationId: id),
                  ),
                ),
              );
              if (box.maxWidth < 1000) return list;
              return Row(
                children: [
                  SizedBox(width: 340, child: list),
                  Expanded(
                    child: Center(
                      child: Text(words(context, 'selectConversation')),
                    ),
                  ),
                ],
              );
            },
          )
        : BlocBuilder<ContactsCubit, ContactsState>(
            bloc: _cubit,
            builder: (context, state) => RefreshIndicator(
              onRefresh: () => _cubit.load(refresh: true),
              child: ListView(
                padding: const EdgeInsets.all(24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (state.items.isEmpty && !state.loading && !state.failed)
                    Text(words(context, 'empty')),
                  for (final item in state.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          title: Text(item['name'] as String),
                          subtitle: widget.propertyId == null
                              ? Text(item['title'] as String)
                              : null,
                          trailing: IconButton(
                            tooltip: words(context, 'contactInterested'),
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => widget.propertyId != null
                                    ? ChatPage(
                                        propertyId: widget.propertyId,
                                        seekerId: item['id'] as String,
                                      )
                                    : ChatPage(
                                        conversationId: item['id'] as String,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (state.loading)
                    const Center(child: CircularProgressIndicator()),
                  if (!state.loading && (state.cursor != null || state.failed))
                    TextButton(
                      onPressed: () => _cubit.load(),
                      child: Text(
                        words(
                          context,
                          state.failed ? 'retry' : 'loadMorePeople',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
  );
}
