import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'models.dart';
import 'api_service.dart';

class PaymentService {
  final File storageFile = File('data/registry.json');
  late WalletData _data;
  late ApiService _api;
  String? _token;
  Timer? _syncTimer;

  Future<void> load() async {
    _api = ApiService(
      baseUrl: 'https://localhost:8888/api/v1',
      allowInsecureLocalhost: true,
    );
    
    await _loadToken();
    
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
    
    // Первоначальная синхронизация
    await _syncCardsFromBackend();
    await _save();
    
    // Запускаем периодическую синхронизацию каждые 10 секунд
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      print('🔄 Periodic sync checking for new cards...');
      await _syncCardsFromBackend();
      await _save();
    });
  }

  void dispose() {
    _syncTimer?.cancel();
  }

  Future<void> _loadToken() async {
    final tokenFile = File('data/token.txt');
    if (await tokenFile.exists()) {
      _token = await tokenFile.readAsString();
    } else {
      _token = await _api.login('user', 'password123');
      if (_token != null) {
        await tokenFile.writeAsString(_token!);
      }
    }
  }

  // Публичный метод для синхронизации (можно вызывать из UI)
  Future<void> syncCards() async {
    await _syncCardsFromBackend();
    await _save();
  }

  Future<void> _syncCardsFromBackend() async {
    if (_token == null) return;
    
    final backendCards = await _api.getCards(token: _token!);
    bool changed = false;
    
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
        print('🆕 NEW CARD ADDED FROM BACKEND: $uid (${backendCard['owner_name']})');
        changed = true;
      }
    }
    
    if (changed) {
      print('✅ Sync completed, new cards added to JSON');
    }
  }

  Future<void> _save() async {
    final encoder = const JsonEncoder.withIndent('  ');
    await storageFile.writeAsString(encoder.convert(_data.toJson()));
    print('💾 JSON saved');
  }

  CardRecord? getCard(String uid) => _data.cardByUid(uid);

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

  Future<bool> pay(String uid, int amount, int terminalId) async {
    // Принудительная синхронизация перед оплатой
    await _syncCardsFromBackend();
    await _save();
    
    final card = _data.cardByUid(uid);
    if (card == null) {
      print('❌ Card not found after sync: $uid');
      return false;
    }
    
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
    final success = await _api.notifyPayment(
      cardNumber: uid,
      amount: amount,
      terminalId: terminalId,
      newBalance: card.balance,
    );
    
    if (!success) {
      print('⚠️ Warning: Failed to notify backend');
    }
    
    return true;
  }

  List<CardRecord> getCards() => _data.cards;
}