class TransactionDTO {
  final String userId;
  final String type;
  final double amount;
  final String account;
  final String target;
  final DateTime time;

  TransactionDTO({
    required this.userId,
    required this.type,
    required this.amount,
    required this.account,
    required this.target,
    required this.time,
  });

  factory TransactionDTO.fromJson(Map<String, dynamic> json) {
    return TransactionDTO(
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      account: json['account'] ?? '',
      target: json['target'] ?? '',
      time: DateTime.parse(json['time'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'type': type,
    'amount': amount,
    'account': account,
    'target': target,
    'time': time.toIso8601String(),
  };
}

class Transaction extends TransactionDTO {
  final String id;

  Transaction({
    required this.id,
    required super.userId,
    required super.type,
    required super.amount,
    required super.account,
    required super.target,
    required super.time,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      account: json['account'] ?? '',
      target: json['target'] ?? '',
      time: DateTime.parse(json['time'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, ...super.toJson()};
}
