// lib/api_service.dart - ПРОСТАЯ ВЕРСИЯ, БЕЗ ТОКЕНОВ
import 'dart:convert';
import 'dart:io';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() => message;
}

class ApiService {
  final String baseUrl;
  final bool allowInsecureLocalhost;

  ApiService({
    required this.baseUrl,
    this.allowInsecureLocalhost = true,
  });

  // Получить баланс карты по номеру (UID) - НЕ ТРЕБУЕТ ТОКЕНА!
  Future<int?> getCardBalance(String cardNumber) async {
    try {
      final response = await _request('GET', '/api/v1/cards/number/$cardNumber');
      
      if (response is Map<String, dynamic>) {
        return response['balance'] as int?;
      }
      return null;
    } catch (e) {
      print('Get card balance error: $e');
      return null;
    }
  }

  // Уведомление об оплате 
  Future<bool> notifyPayment({
    required String cardNumber,
    required int amount,
    required int terminalId,
    required int newBalance,
  }) async {
    try {
      final response = await _request(
        'POST',
        '/api/v1/payments/notify',
        body: {
          'card_number': cardNumber,
          'amount': amount,
          'terminal_id': terminalId,
          'new_balance': newBalance,
        },
      );
      return response != null;
    } catch (e) {
      print('Notify payment error: $e');
      return false;
    }
  }

  // Создать карту - НЕ ТРЕБУЕТ ТОКЕНА?
  // Но лучше создать через админку или напрямую в БД
  // Если нужен - можно добавить, но лучше через админку

  // Базовый метод для HTTP запросов
  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    if (allowInsecureLocalhost) {
      client.badCertificateCallback = (
        X509Certificate cert,
        String host,
        int port,
      ) {
        return host == 'localhost' || host == '127.0.0.1';
      };
    }

    try {
      final uri = _buildUri(path);
      print('📡 $method $uri');
      
      final request = await client.openUrl(method, uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      
      if (body != null) {
        final jsonBody = jsonEncode(body);
        print('📦 Body: $jsonBody');
        request.write(jsonBody);
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      print('📡 Response status: ${response.statusCode}');
      if (responseBody.isNotEmpty) {
        print('📡 Response: $responseBody');
      }

      final parsed = responseBody.trim().isEmpty ? null : jsonDecode(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _extractError(parsed) ??
            'Request failed with status ${response.statusCode}.';
        throw ApiException(message, statusCode: response.statusCode);
      }

      return parsed;
    } on HandshakeException catch (error) {
      print('❌ Handshake error: $error');
      throw ApiException(
        'TLS handshake failed for $baseUrl. ${error.message}',
      );
    } on SocketException catch (error) {
      print('❌ Socket error: $error');
      throw ApiException(
        'Failed to connect to $baseUrl. Make sure the backend is running. ${error.message}',
      );
    } finally {
      client.close(force: true);
    }
  }

  Uri _buildUri(String path) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$normalizedBase$cleanPath');
  }

  Future<Map<String, dynamic>?> getCardData(String cardNumber) async {
    try {
      final response = await _request('GET', '/api/v1/cards/number/$cardNumber');
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      print('Get card data error: $e');
      return null;
    }
  }

  String? _extractError(Object? parsed) {
    if (parsed is Map<String, dynamic>) {
      final direct = parsed['error'] ?? parsed['message'];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct.trim();
      }
    } else if (parsed is String && parsed.trim().isNotEmpty) {
      return parsed.trim();
    }
    return null;
  }
}