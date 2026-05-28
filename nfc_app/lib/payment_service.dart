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
    // Ждем карту до 20 секунд
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) return (null, null, null);
    
    final balance = await _card.readBalance();
    final registry = await _loadRegistry();
    final ownerName = registry[uid];
    
    return (uid, ownerName, balance);
  }
  
  Future<bool> registerCard(String ownerName, int initialBalance) async {
    return await initCard(ownerName, initialBalance);
  }
  
  Future<bool> initCard(String ownerName, int initialBalance) async {
    print('🔍 Tap your card to initialize...');
    
    // Ждем карту до 20 секунд
    String? uid;
    for (int i = 0; i < 60; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) {
      print('❌ No card detected');
      return false;
    }
    
    print('✅ Card detected: $uid');
    
    final registry = await _loadRegistry();
    registry[uid] = ownerName;
    await _saveRegistry(registry);
    
    final success = await _card.writeBalance(initialBalance);
    
    if (success) {
      print('✅ Card initialized with $initialBalance RUB');
      print('   Owner: $ownerName');
      return true;
    } else {
      print('❌ Failed to write to card');
      return false;
    }
  }
  
  Future<bool> _isCardInBackend() async {
    // Ждем карту до 20 секунд
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
    // Ждем карту до 20 секунд
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
    print('🔄 Syncing with backend...');
    
    // Ждем карту до 20 секунд
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) {
      print('❌ No card detected');
      return false;
    }

    onCardDetected?.call();
    
    final backendBalance = await _api.getCardBalance(uid);
    if (backendBalance == null) {
      print('❌ Card not found in backend');
      return false;
    }
    
    final cardBalance = await _card.readBalance();
    print('💰 Backend balance: $backendBalance RUB');
    print('💳 Card balance: $cardBalance RUB');
    
    if (backendBalance != cardBalance) {
      final success = await _card.writeBalance(backendBalance);
      if (success) {
        print('✅ Card synced! New balance: $backendBalance RUB');
        return true;
      } else {
        print('❌ Failed to write to card');
        return false;
      }
    } else {
      print('✅ Balances already in sync');
      return true;
    }
  }

  // Возвращает null при успехе, иначе строку с ошибкой
  // НЕ возвращает ошибку если карта просто не приложена - даем 20 секунд в UI
  Future<String?> pay() async {
    // Ждем карту до 20 секунд (UI сам отсчитывает время)
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) {
      return null; // Не нашли карту - просто возвращаем null, UI покажет таймаут
    }

    onCardDetected?.call();
    
    // Проверяем наличие карты в бекенде
    final cardData = await _api.getCardData(uid);
    if (cardData == null) {
      return '❌ Карта удалена из системы! Обратитесь к администратору.';
    }
    
    if (cardData['blocked'] == true) {
      return '❌ Карта заблокирована! Обратитесь к администратору.';
    }
    
    // Читаем баланс с карты
    final currentBalance = await _card.readBalance();
    if (currentBalance == null) {
      return '❌ Не удалось прочитать карту';
    }
    
    if (currentBalance < 50) {
      return '❌ Недостаточно средств! Баланс: $currentBalance руб.';
    }
    
    // Списываем
    final newBalance = currentBalance - 50;
    final success = await _card.writeBalance(newBalance);
    
    if (success) {
      print('✅ Payment: 50 RUB, new balance: $newBalance RUB');
      await _api.notifyPayment(
        cardNumber: uid,
        amount: 50,
        terminalId: 1,
        newBalance: newBalance,
      );
      return null; // Успех
    } else {
      return '❌ Ошибка при списании средств';
    }
  }
  
  // Возвращает null при успехе, иначе строку с ошибкой
  // НЕ возвращает ошибку если карта просто не приложена - даем 20 секунд в UI
  Future<String?> replenish() async {
    // Ждем карту до 20 секунд
    String? uid;
    for (int i = 0; i < 40; i++) {
      uid = await _card.readUid();
      if (uid != null) break;
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (uid == null) {
      return null; // Не нашли карту - просто возвращаем null
    }

    onCardDetected?.call();
    
    final cardData = await _api.getCardData(uid);
    if (cardData == null) {
      return '❌ Карта удалена из системы! Обратитесь к администратору.';
    }
    
    if (cardData['blocked'] == true) {
      return '❌ Карта заблокирована! Обратитесь к администратору.';
    }
    
    final currentBalance = await _card.readBalance();
    if (currentBalance == null) {
      return '❌ Не удалось прочитать карту';
    }
    
    // Пополняем
    final newBalance = currentBalance + 500;
    final success = await _card.writeBalance(newBalance);
    
    if (success) {
      print('✅ Replenishment: +500 RUB, new balance: $newBalance RUB');
      await _api.notifyPayment(
        cardNumber: uid,
        amount: 500,
        terminalId: 1,
        newBalance: newBalance,
      );
      return null; // Успех
    } else {
      return '❌ Ошибка при пополнении';
    }
  }
  
  Future<int?> checkBalance() async {
    // Ждем карту до 20 секунд
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