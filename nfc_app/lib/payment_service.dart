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
  
  // Загружаем реестр карт (UID -> Owner Name)
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
  
  // Получить информацию с карты
  Future<(String? uid, String? ownerName, int? balance)> getCardInfo() async {
    final uid = await _card.readUid();
    if (uid == null) return (null, null, null);
    
    final balance = await _card.readBalance();
    final registry = await _loadRegistry();
    final ownerName = registry[uid];
    
    return (uid, ownerName, balance);
  }
  
  // Регистрация карты (для CLI)
  Future<bool> registerCard(String ownerName, int initialBalance) async {
    return await initCard(ownerName, initialBalance);
  }
  
  // Инициализация карты
  Future<bool> initCard(String ownerName, int initialBalance) async {
    print('🔍 Tap your card to initialize...');
    
    final uid = await _card.readUid();
    if (uid == null) {
      print('❌ No card detected');
      return false;
    }
    
    print('✅ Card detected: $uid');
    
    // Сохраняем имя локально для UI
    final registry = await _loadRegistry();
    registry[uid] = ownerName;
    await _saveRegistry(registry);
    
    // Записываем баланс на карту
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
  
  // Синхронизация - берем баланс с бекенда и пишем на карту
  Future<bool> syncWithBackend() async {
    print('🔄 Syncing with backend...');
    
    final uid = await _card.readUid();
    if (uid == null) {
      print('❌ No card detected');
      return false;
    }
    
    final backendBalance = await _api.getCardBalance(uid);
    if (backendBalance == null) {
      print('❌ Card not found in backend');
      print('   Create it first in admin panel with number: $uid');
      return false;
    }
    
    final cardBalance = await _card.readBalance();
    print('💰 Backend balance: $backendBalance RUB');
    print('💳 Card balance: $cardBalance RUB');
    
    if (backendBalance != cardBalance) {
      final success = await _card.writeBalance(backendBalance);
      if (success) {
        print('✅ Card synced! New balance: $backendBalance RUB');
      } else {
        print('❌ Failed to write to card');
        return false;
      }
    } else {
      print('✅ Balances already in sync');
    }
    
    return true;
  }
  
  // Оплата
  Future<bool> pay() async {
    final uid = await _card.readUid();
    if (uid == null) return false;
    
    final currentBalance = await _card.readBalance();
    if (currentBalance == null) return false;
    if (currentBalance < 50) {
      print('❌ Insufficient funds: $currentBalance RUB');
      return false;
    }
    
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
    }
    return success;
  }
  
  // Пополнение
  Future<bool> replenish() async {
    final uid = await _card.readUid();
    if (uid == null) return false;
    
    final currentBalance = await _card.readBalance();
    if (currentBalance == null) return false;
    
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
    }
    return success;
  }
  
  // Проверить баланс
  Future<int?> checkBalance() async {
    return await _card.readBalance();
  }
}