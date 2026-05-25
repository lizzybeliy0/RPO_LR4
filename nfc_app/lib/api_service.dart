import 'dart:convert';
import 'dart:io';

class ApiService {
  final String baseUrl = 'http://localhost:8080/api/v1';

  // Уведомление об оплате (синхронизация с бэкендом)
  Future<bool> notifyPayment({
    required String cardNumber,
    required int amount,
    required int terminalId,
    required int newBalance,
  }) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('$baseUrl/payments/notify'));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'card_number': cardNumber,
        'amount': amount,
        'terminal_id': terminalId,
        'new_balance': newBalance,
      }));
      
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      print('Notify payment error: $e');
      return false;
    }
  }

  // Получить все карты из бэкенда (при запуске)
  Future<List<Map<String, dynamic>>> getCards() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$baseUrl/cards'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.transform(utf8.decoder).join()) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get cards error: $e');
      return [];
    }
  }
}