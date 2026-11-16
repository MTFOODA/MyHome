class ChatFailure implements Exception {
  final String code;
  const ChatFailure(this.code);
}

class ChatMessage {
  final int id;
  final String text, alias;
  final bool mine;
  final DateTime? createdAt;
  const ChatMessage(
    this.id,
    this.text,
    this.alias,
    this.mine, {
    this.createdAt,
  });
  factory ChatMessage.fromJson(Map<String, dynamic> value) => ChatMessage(
    value['id'] as int,
    value['text'] as String,
    value['sender_alias'] as String,
    value['mine'] as bool,
    createdAt: DateTime.tryParse('${value['created_at']}'),
  );
}

class ChatBatch {
  final List<ChatMessage> messages;
  final int? before;
  const ChatBatch(this.messages, this.before);
}

abstract class ChatRepository {
  Future<Map<String, dynamic>> metadata(String id);
  Future<String> openDeal(String id);
  Future<String> openGroup(String id);
  Future<String> openProperty(String id, {String? seekerId});
  Future<Map<String, dynamic>> inbox({String? before});
  Future<ChatBatch> read(String id, {int? before, int? after});
  Future<ChatMessage> send(String id, String text);
}
