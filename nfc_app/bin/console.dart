import 'dart:io';
import '../lib/nfc_service.dart';
import '../lib/payment_service.dart';

void main(List<String> args) async {
  final nfc = NfcService();
  final payment = PaymentService();
  await payment.load();

  if (args.isEmpty) {
    print('''
NFC Кошелек

Команды:
  register "ФИО" [баланс]  - Зарегистрировать карту
  pay                      - Оплатить проезд (50 руб.)
  info                     - Информация о карте
  list                     - Все карты
''');
    return;
  }

  final command = args[0].toLowerCase();

  switch (command) {
    case 'register':
      final name = args.length > 1 ? args[1] : null;
      final balanceStr = args.length > 2 ? args[2] : '10000';
      final balance = int.tryParse(balanceStr) ?? 10000;
      
      if (name == null) {
        print('❌ Использование: register "ФИО" [баланс]');
        return;
      }
      if (balance <= 0) {
        print('❌ Баланс должен быть положительным');
        return;
      }
      
      print('🔍 Приложите карту...');
      final uid = await nfc.readCardUid();
      if (uid == null) {
        print('❌ Карта не найдена');
        return;
      }
      final success = await payment.registerCard(uid, name, balance);
      if (success) {
        print('✅ Карта зарегистрирована: $name ($balance руб.)');
        print('📁 Данные сохранены в data/registry.json');
      } else {
        print('❌ Карта уже существует');
      }
      break;

    case 'pay':
      print('💳 Приложите карту для оплаты (50 руб.)...');
      final uid = await nfc.readCardUid();
      if (uid == null) {
        print('❌ Карта не найдена');
        return;
      }
      final success = await payment.pay(uid, 50);
      if (success) {
        final card = payment.getCard(uid);
        print('✅ Оплачено 50 руб. Баланс: ${card?.balance ?? 0} руб.');
        print('📁 Данные обновлены в data/registry.json');
      } else {
        print('❌ Ошибка оплаты. Карта не зарегистрирована или недостаточно средств');
      }
      break;

    case 'info':
      print('🔍 Приложите карту...');
      final uid = await nfc.readCardUid();
      if (uid == null) {
        print('❌ Карта не найдена');
        return;
      }
      final card = payment.getCard(uid);
      if (card == null) {
        print('❌ Карта не зарегистрирована');
      } else {
        print('''
📇 ИНФОРМАЦИЯ О КАРТЕ
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Владелец: ${card.ownerName}
Баланс: ${card.balance} руб.
UID: ${card.uid}
''');
      }
      break;

    case 'list':
      final cards = payment.getCards();
      if (cards.isEmpty) {
        print('📭 Нет зарегистрированных карт');
      } else {
        print('📇 ЗАРЕГИСТРИРОВАННЫЕ КАРТЫ');
        for (final card in cards) {
          print('${card.ownerName}: ${card.balance} руб. (UID: ${card.uid})');
        }
      }
      break;

    default:
      print('❌ Неизвестная команда: $command');
  }
}