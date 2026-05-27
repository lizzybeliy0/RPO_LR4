// bin/console.dart
import 'dart:io';
import '../lib/card_storage.dart';

void main(List<String> args) async {
  final card = CardStorage();

  if (args.isEmpty) {
    print('''
NFC Wallet - только карта, без базы данных

Commands:
  init [balance]    - Записать баланс на карту (по умолчанию 500)
  pay               - Списать 50 руб.
  add               - Добавить 500 руб.
  info              - Показать баланс карты
''');
    return;
  }

  final command = args[0].toLowerCase();

  switch (command) {
    case 'init':
      final balanceStr = args.length > 1 ? args[1] : '500';
      final balance = int.tryParse(balanceStr) ?? 500;
      
      print('🔍 Приложите карту...');
      
      final uid = await card.readUid();
      if (uid == null) {
        print('❌ Карта не обнаружена');
        return;
      }
      
      print('✅ Карта: $uid');
      print('💰 Записываем баланс $balance руб...');
      
      final success = await card.writeBalance(balance);
      
      if (success) {
        print('✅ Баланс записан!');
        print('   Баланс: $balance RUB');
      } else {
        print('❌ Ошибка записи');
      }
      break;

    case 'pay':
      print('💳 Приложите карту для оплаты 50 руб...');
      
      final currentBalance = await card.readBalance();
      if (currentBalance == null) {
        print('❌ Не удалось прочитать карту');
        return;
      }
      
      if (currentBalance < 50) {
        print('❌ Недостаточно средств: $currentBalance RUB');
        return;
      }
      
      final newBalance = currentBalance - 50;
      final success = await card.writeBalance(newBalance);
      
      if (success) {
        print('✅ Оплачено 50 руб');
        print('   Новый баланс: $newBalance RUB');
      } else {
        print('❌ Ошибка оплаты');
      }
      break;

    case 'add':
      print('💰 Приложите карту для пополнения на 500 руб...');
      
      final currentBalance = await card.readBalance();
      if (currentBalance == null) {
        print('❌ Не удалось прочитать карту');
        return;
      }
      
      final newBalance = currentBalance + 500;
      final success = await card.writeBalance(newBalance);
      
      if (success) {
        print('✅ Пополнено 500 руб');
        print('   Новый баланс: $newBalance RUB');
      } else {
        print('❌ Ошибка пополнения');
      }
      break;

    case 'info':
      print('🔍 Приложите карту...');
      
      final balance = await card.readBalance();
      
      if (balance != null) {
        print('''
💰 БАЛАНС КАРТЫ
━━━━━━━━━━━━━
${balance} RUB
''');
      } else {
        print('❌ Не удалось прочитать карту');
      }
      break;

    default:
      print('❌ Неизвестная команда: $command');
  }
}