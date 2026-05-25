import 'dart:convert';
import 'dart:io';
import 'models.dart';
import 'api_service.dart';

class PaymentService {
  final File storageFile = File('data/registry.json');
  late WalletData _data;
  final ApiService _api = ApiService();

  Future<void> load() async {
    await storageFile.parent.create(recursive: true);
    
    if (await storageFile.exists()) {
      final content = await storageFile.readAsString();
      if (content.trim().isNotEmpty) {
        try {
          final json = jsonDecode(content) as Map<String, dynamic>;
          _data = WalletData.fromJson(json);
        } catch (e) {
          _data = WalletData(cards: [], transactions: []);
        }
      } else {
        _data = WalletData(cards: [], transactions: []);
      }
    } else {
      _data = WalletData(cards: [], transactions: []);
    }
    
    await _syncCardsFromBackend();
    await _save();
  }

  Future<void> _syncCardsFromBackend() async {
    final backendCards = await _api.getCards();
    
    for (final backendCard in backendCards) {
      final uid = backendCard['number'];
      if (_data.cardByUid(uid) == null) {
        _data.cards.add(CardRecord(
          uid: uid,
          ownerName: backendCard['owner_name'],
          balance: backendCard['balance'],
          status: backendCard['blocked'] ? 'blocked' : 'active',
          keyId: backendCard['key_id'],
        ));
        print('🆕 New card from backend: $uid');
      }
    }
  }

  Future<void> _save() async {
    final encoder = const JsonEncoder.withIndent('  ');
    await storageFile.writeAsString(encoder.convert(_data.toJson()));
  }

  CardRecord? getCard(String uid) => _data.cardByUid(uid);

  // Регистрация новой карты (только в локальный JSON)
  Future<bool> registerCard(String uid, String ownerName, int balance) async {
    if (_data.cardByUid(uid) != null) return false;

    _data.cards.add(CardRecord(
      uid: uid,
      ownerName: ownerName,
      balance: balance,
      status: 'active',
      keyId: 1,
    ));
    await _save();
    return true;
  }

  // Оплата (требует terminalId)
  Future<bool> pay(String uid, int amount, int terminalId) async {
    final card = _data.cardByUid(uid);
    if (card == null) return false;
    if (card.balance < amount) return false;
    if (card.status != 'active') return false;

    // Списываем в JSON
    card.balance -= amount;
    
    // Записываем транзакцию
    _data.transactions.add(TransactionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardUid: uid,
      amount: amount,
      type: 'payment',
      success: true,
      balanceAfter: card.balance,
      createdAt: DateTime.now(),
    ));
    await _save();
    
    // Уведомляем бэкенд
    await _api.notifyPayment(
      cardNumber: uid,
      amount: amount,
      terminalId: terminalId,
      newBalance: card.balance,
    );
    
    return true;
  }

  List<CardRecord> getCards() => _data.cards;
}