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

  // Уведомление об оплате (не требует токена)
  Future<bool> notifyPayment({
    required String cardNumber,
    required int amount,
    required int terminalId,
    required int newBalance,
  }) async {
    try {
      final response = await _request(
        'POST',
        '/payments/notify',
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

  // Получить список карт (требует токен)
  Future<List<Map<String, dynamic>>> getCards({required String token}) async {
    try {
      final client = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      
      final request = await client.getUrl(Uri.parse('$baseUrl/cards'));
      request.headers.set('Authorization', 'Bearer $token');
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.transform(utf8.decoder).join()) as List;
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        throw Exception('invalid_token');
      }
      return [];
    } catch (e) {
      print('Get cards error: $e');
      rethrow;
    }
  }

  // Логин для получения токена
  Future<String?> login(String login, String password) async {
    try {
      final response = await _request(
        'POST',
        '/auth/login',
        body: {
          'login': login,
          'password': password,
        },
      );
      if (response is Map<String, dynamic>) {
        return response['token'] as String?;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Базовый метод для HTTP запросов
  Future<Object?> _request(
    String method,
    String path, {
    String? token,
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
      final request = await client.openUrl(method, _buildUri(path));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final parsed = responseBody.trim().isEmpty ? null : jsonDecode(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _extractError(parsed) ??
            'Request failed with status ${response.statusCode}.';
        throw ApiException(message, statusCode: response.statusCode);
      }

      return parsed;
    } on HandshakeException catch (error) {
      throw ApiException(
        'TLS handshake failed for $baseUrl. ${error.message}',
      );
    } on SocketException catch (error) {
      throw ApiException(
        'Failed to connect to $baseUrl. Make sure the backend is running. ${error.message}',
      );
    } finally {
      client.close(force: true);
    }
  }

  Uri _buildUri(String path) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalizedBase)
        .resolve(path.startsWith('/') ? path.substring(1) : path);
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