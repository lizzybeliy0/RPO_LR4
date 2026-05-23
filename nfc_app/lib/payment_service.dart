import 'dart:convert';
import 'dart:io';
import 'models.dart';

class PaymentService {
  final File storageFile = File('data/registry.json');
  late WalletData _data;

  Future<void> load() async {
    // Создаём папку data, если её нет
    await storageFile.parent.create(recursive: true);
    
    if (await storageFile.exists()) {
      final content = await storageFile.readAsString();
      // Если файл пустой или содержит только пробелы — создаём новую структуру
      if (content.trim().isEmpty) {
        _data = WalletData(cards: [], transactions: []);
        await _save();
        return;
      }
      
      try {
        final json = jsonDecode(content) as Map<String, dynamic>;
        _data = WalletData.fromJson(json);
      } catch (e) {
        // Если JSON повреждён — создаём новую структуру
        print('⚠️ Файл данных повреждён, создаём новый');
        _data = WalletData(cards: [], transactions: []);
        await _save();
      }
    } else {
      _data = WalletData(cards: [], transactions: []);
      await _save();
    }
  }

  Future<void> _save() async {
    final encoder = const JsonEncoder.withIndent('  ');
    await storageFile.writeAsString(encoder.convert(_data.toJson()));
  }

  CardRecord? getCard(String uid) => _data.cardByUid(uid);

  Future<bool> registerCard(String uid, String ownerName, int balance) async {
    if (_data.cardByUid(uid) != null) return false;

    final now = DateTime.now().toIso8601String();
    _data.cards.add(CardRecord(
      uid: uid,
      ownerName: ownerName,
      balance: balance,
      createdAt: now,
      updatedAt: now,
    ));
    await _save();
    return true;
  }

  Future<bool> pay(String uid, int amount) async {
    final card = _data.cardByUid(uid);
    if (card == null) return false;
    if (card.balance < amount) return false;

    card.balance -= amount;
    card.updatedAt = DateTime.now().toIso8601String();
    _data.transactions.add(TransactionRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardUid: uid,
      amount: amount,
      type: 'payment',
      success: true,
      message: 'Оплата проезда',
      balanceAfter: card.balance,
      createdAt: DateTime.now().toIso8601String(),
    ));
    await _save();
    return true;
  }

  List<CardRecord> getCards() => _data.cards;
}