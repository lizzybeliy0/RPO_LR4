class CardRecord {
  final String uid;
  final String ownerName;
  int balance;
  final String createdAt;
  String updatedAt;

  CardRecord({
    required this.uid,
    required this.ownerName,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'ownerName': ownerName,
    'balance': balance,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory CardRecord.fromJson(Map<String, dynamic> json) => CardRecord(
    uid: json['uid'],
    ownerName: json['ownerName'],
    balance: json['balance'],
    createdAt: json['createdAt'],
    updatedAt: json['updatedAt'],
  );
}

class TransactionRecord {
  final String id;
  final String cardUid;
  final int amount;
  final String type;
  final bool success;
  final String message;
  final int balanceAfter;
  final String createdAt;

  TransactionRecord({
    required this.id,
    required this.cardUid,
    required this.amount,
    required this.type,
    required this.success,
    required this.message,
    required this.balanceAfter,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cardUid': cardUid,
    'amount': amount,
    'type': type,
    'success': success,
    'message': message,
    'balanceAfter': balanceAfter,
    'createdAt': createdAt,
  };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) => TransactionRecord(
    id: json['id'],
    cardUid: json['cardUid'],
    amount: json['amount'],
    type: json['type'],
    success: json['success'],
    message: json['message'],
    balanceAfter: json['balanceAfter'],
    createdAt: json['createdAt'],
  );
}

class WalletData {
  List<CardRecord> cards;
  List<TransactionRecord> transactions;

  WalletData({required this.cards, required this.transactions});

  Map<String, dynamic> toJson() => {
    'cards': cards.map((c) => c.toJson()).toList(),
    'transactions': transactions.map((t) => t.toJson()).toList(),
  };

  factory WalletData.fromJson(Map<String, dynamic> json) => WalletData(
    cards: (json['cards'] as List).map((c) => CardRecord.fromJson(c)).toList(),
    transactions: (json['transactions'] as List).map((t) => TransactionRecord.fromJson(t)).toList(),
  );

  CardRecord? cardByUid(String uid) {
    try {
      return cards.firstWhere((c) => c.uid == uid);
    } catch (_) {
      return null;
    }
  }
}