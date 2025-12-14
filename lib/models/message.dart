class MessageDTO {
  final String userId;
  final String sender;
  final String messageContent;
  final DateTime time;

  MessageDTO({
    required this.userId,
    required this.sender,
    required this.messageContent,
    required this.time,
  });

  factory MessageDTO.fromJson(Map<String, dynamic> json) {
    return MessageDTO(
      userId: json['userId'] ?? '',
      sender: json['sender'] ?? '',
      messageContent: json['messageContent'] ?? '',
      time: json['time'] != null
          ? DateTime.parse(json['time'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'sender': sender,
    'messageContent': messageContent,
    'time': time.toIso8601String(),
  };
}

class Message extends MessageDTO {
  final String id;

  Message({
    required this.id,
    required super.userId,
    required super.sender,
    required super.messageContent,
    required super.time,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      sender: json['sender'] ?? '',
      messageContent: json['messageContent'] ?? '',
      time: json['time'] != null
          ? DateTime.parse(json['time'])
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, ...super.toJson()};
}
