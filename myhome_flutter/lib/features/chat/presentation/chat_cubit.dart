import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/chat_repository.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool loading, sending, olderLoading;
  final int? before;
  final String? error;
  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.olderLoading = false,
    this.before,
    this.error,
  });
}

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository repository;
  final String? dealId, groupId, propertyId, seekerId, conversationId;
  String? _id;
  Timer? _timer;
  bool _polling = false;
  ChatCubit(
    this.repository, {
    this.dealId,
    this.groupId,
    this.propertyId,
    this.seekerId,
    this.conversationId,
  }) : super(const ChatState());
  List<ChatMessage> _merge(List<ChatMessage> incoming) {
    final values = {
      for (final message in [...state.messages, ...incoming])
        message.id: message,
    };
    return values.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<void> open() async {
    if (isClosed) return;
    _timer?.cancel();
    emit(const ChatState(loading: true));
    try {
      _id =
          conversationId ??
          (propertyId != null
              ? await repository.openProperty(propertyId!, seekerId: seekerId)
              : dealId != null
              ? await repository.openDeal(dealId!)
              : await repository.openGroup(groupId!));
      final batch = await repository.read(_id!);
      if (isClosed) return;
      emit(ChatState(messages: batch.messages, before: batch.before));
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => poll());
    } on ChatFailure catch (e) {
      if (!isClosed) emit(ChatState(error: e.code));
    } catch (_) {
      if (!isClosed) emit(const ChatState(error: 'NETWORK_ERROR'));
    }
  }

  Future<void> poll() async {
    if (isClosed || _polling || _id == null || state.loading) return;
    _polling = true;
    try {
      final batch = await repository.read(
        _id!,
        after: state.messages.isEmpty ? 0 : state.messages.last.id,
      );
      if (!isClosed) {
        emit(
          ChatState(
            messages: _merge(batch.messages),
            before: state.before,
            sending: state.sending,
            olderLoading: state.olderLoading,
          ),
        );
      }
    } on ChatFailure catch (e) {
      if (!isClosed) {
        final revoked = [
          'CHAT_ACCESS_REVOKED',
          'CONVERSATION_NOT_FOUND',
          'DEAL_NOT_FOUND',
        ].contains(e.code);
        if (revoked) _timer?.cancel();
        emit(
          ChatState(
            messages: revoked ? const [] : state.messages,
            before: state.before,
            error: e.code,
            sending: state.sending,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          ChatState(
            messages: state.messages,
            before: state.before,
            sending: state.sending,
            error: 'NETWORK_ERROR',
          ),
        );
      }
    } finally {
      _polling = false;
    }
  }

  Future<bool> send(String text) async {
    if (isClosed || state.sending || _id == null || text.trim().isEmpty) {
      return false;
    }
    emit(
      ChatState(messages: state.messages, before: state.before, sending: true),
    );
    try {
      final message = await repository.send(_id!, text.trim());
      if (!isClosed) {
        emit(ChatState(messages: _merge([message]), before: state.before));
      }
      return true;
    } on ChatFailure catch (e) {
      if (!isClosed) {
        emit(
          ChatState(
            messages: state.messages,
            before: state.before,
            error: e.code,
          ),
        );
      }
      return false;
    } catch (_) {
      if (!isClosed) {
        emit(
          ChatState(
            messages: state.messages,
            before: state.before,
            error: 'NETWORK_ERROR',
          ),
        );
      }
      return false;
    }
  }

  Future<void> older() async {
    if (isClosed || state.olderLoading || state.before == null || _id == null) {
      return;
    }
    emit(
      ChatState(
        messages: state.messages,
        before: state.before,
        olderLoading: true,
        sending: state.sending,
      ),
    );
    try {
      final batch = await repository.read(_id!, before: state.before);
      if (!isClosed) {
        emit(
          ChatState(
            messages: _merge(batch.messages),
            before: batch.before,
            sending: state.sending,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          ChatState(
            messages: state.messages,
            before: state.before,
            error: 'NETWORK_ERROR',
            sending: state.sending,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
