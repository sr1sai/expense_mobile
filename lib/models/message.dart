class MessageDTO {
  final String userId;
  final String messageContent;

  MessageDTO({required this.userId, required this.messageContent});

  factory MessageDTO.fromJson(Map<String, dynamic> json) {
    return MessageDTO(
      userId: json['userId'] ?? '',
      messageContent: json['messageContent'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'messageContent': messageContent,
  };
}

class Message extends MessageDTO {
  final String id;

  Message({
    required this.id,
    required String userId,
    required String messageContent,
  }) : super(userId: userId, messageContent: messageContent);

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      messageContent: json['messageContent'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, ...super.toJson()};
}
