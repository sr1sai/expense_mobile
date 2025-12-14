class PaymentDTO {
  final String userId;
  final String messageId;

  PaymentDTO({required this.userId, required this.messageId});

  factory PaymentDTO.fromJson(Map<String, dynamic> json) {
    return PaymentDTO(
      userId: json['userId'] ?? '',
      messageId: json['messageId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'userId': userId, 'messageId': messageId};
}

class Payment extends PaymentDTO {
  final String id;

  Payment({required this.id, required super.userId, required super.messageId});

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      messageId: json['messageId'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, ...super.toJson()};
}
