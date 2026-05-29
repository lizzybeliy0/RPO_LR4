// lib/payment_service.dart
import 'dart:convert';
import 'dart:io';
import 'card_storage.dart';
import 'api_service.dart';

class PaymentService {
  final CardStorage _card = CardStorage();
  final ApiService _api = ApiService(
    baseUrl: 'https://localhost:8888',
    allowInsecureLocalhost: true,
  );
  final String registryPath = 'card_registry.json';

  Function? onCardDetected;
  
  Future<Map<String, String>> _loadRegistry() async {
    final file = File(registryPath);
    if (!await file.exists()) return {};
    try {
      final content = await file.readAsString();
      return Map<String, String>.from(jsonDecode(content));
    } catch (e) {
      return {};
    }
  }
  
  Future<void> _saveRegistry(Map<String, String> registry) async {
    final file = File(registryPath);
    await file.writeAsString(jsonEncode(registry));
  }
  
  Future<(String? uid, String? ownerName, int? balance)> getCardInfo() async {
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) return (null, null, null);
    
    // 🔴 ИСПРАВЛЕНО: используем readBalance
    final balance = await _card.readBalance();
    final registry = await _loadRegistry();
    final ownerName = registry[uid];
    
    return (uid, ownerName, balance);
  }
  
  Future<bool> registerCard(String ownerName, int initialBalance) async {
    return await initCard(ownerName, initialBalance);
  }
  
  Future<bool> initCard(String ownerName, int initialBalance) async {
    print('   Tap your card to initialize...');
    
    String? uid;
    for (int i = 0; i < 60; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) {
      print('   No card detected');
      return false;
    }
    
    print('   !!!Card detected: $uid');
    
    final registry = await _loadRegistry();
    registry[uid] = ownerName;
    await _saveRegistry(registry);
    
    // 🔴 ИСПРАВЛЕНО: используем updateBalance для установки начального баланса
    // Для инициализации нужно установить баланс, а не изменить на дельту
    // Поэтому используем отдельный метод или читаем и записываем
    // Пока оставим writeBalance, но его нужно добавить обратно
    final success = await _card.writeBalance(initialBalance);
    
    if (success) {
      print('   Card initialized with $initialBalance RUB');
      print('   Owner: $ownerName');
      return true;
    } else {
      print('   Failed to write to card');
      return false;
    }
  }
  
  Future<bool> _isCardInBackend() async {
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) return false;
    
    final balance = await _api.getCardBalance(uid);
    return balance != null;
  }
  
  Future<int?> getBackendBalance() async {
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) return null;
    return await _api.getCardBalance(uid);
  }
  
  Future<bool> syncWithBackend() async {
    print('   Syncing with backend...');
    
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) {
      print('   No card detected');
      return false;
    }

    onCardDetected?.call();
    
    final backendBalance = await _api.getCardBalance(uid);
    if (backendBalance == null) {
      print('   Card not found in backend');
      return false;
    }
    
    final cardBalance = await _card.readBalance();
    print('   !Backend balance: $backendBalance RUB');
    print('   !Card balance: $cardBalance RUB');
    
    if (backendBalance != cardBalance) {
      // 🔴 ИСПРАВЛЕНО: для синхронизации нужно установить конкретный баланс
      // updateBalance с дельтой не подходит, нужен writeBalance
      final success = await _card.writeBalance(backendBalance);
      if (success) {
        print('   !!!Card synced! New balance: $backendBalance RUB');
        return true;
      } else {
        print('   Failed to write to card');
        return false;
      }
    } else {
      print('   !!!Balances already in sync');
      return true;
    }
  }

// lib/payment_service.dart - исправленный pay()

  Future<String?> pay() async {
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) return null;

    onCardDetected?.call();
    
    final cardData = await _api.getCardData(uid);
    if (cardData == null) {
      return 'Карта удалена из системы! Обратитесь к администратору.';
    }
    
    if (cardData['blocked'] == true) {
      return 'Карта заблокирована! Обратитесь к администратору.';
    }
    
    final result = await _card.updateBalance(-50);
    
    if (result.success) {
      print('   Payment: 50 RUB successful, new balance: ${result.newBalance}');
      await _api.notifyPayment(
        cardNumber: uid,
        amount: 50,
        terminalId: 1,
        newBalance: result.newBalance!,
      );
      return null;
    } else {
      return result.error;  // ← точное сообщение об ошибке
    }
  }

  Future<String?> replenish() async {
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) return null;

    onCardDetected?.call();
    
    final cardData = await _api.getCardData(uid);
    if (cardData == null) {
      return 'Карта удалена из системы! Обратитесь к администратору.';
    }
    
    if (cardData['blocked'] == true) {
      return 'Карта заблокирована! Обратитесь к администратору.';
    }
    
    final result = await _card.updateBalance(500);
    
    if (result.success) {
      print('   Replenishment: +500 RUB successful, new balance: ${result.newBalance}');
      await _api.notifyPayment(
        cardNumber: uid,
        amount: 500,
        terminalId: 1,
        newBalance: result.newBalance!,
      );
      return null;
    } else {
      return result.error;
    }
  }

  Future<int?> checkBalance() async {
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 5));
    }
    
    if (uid == null) return null;
    return await _card.readBalance();
  }
}