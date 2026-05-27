// lib/card_storage.dart
import 'dart:io';
import 'dart:convert';

class CardStorage {
  final String nfcListPath = r'C:\Users\Lizaveta\MGTU_Study\rpo2\lab4\libs\libnfc\build\utils\nfc-list.exe';
  final String nfcMfClassicPath = r'C:\Users\Lizaveta\MGTU_Study\rpo2\lab4\libs\libnfc\build\utils\nfc-mfclassic.exe';
  String? _cachedComPort;
  
  static const String defaultKey = 'F';
  
  Future<String?> _findComPort() async {
    try {
      final result = await Process.run('powershell', [
        '-Command',
        '[System.IO.Ports.SerialPort]::getportnames()'
      ]);
      
      final ports = (result.stdout as String)
          .trim()
          .split('\r\n')
          .where((p) => p.trim().isNotEmpty)
          .toList();
      
      for (final port in ports) {
        try {
          final testResult = await Process.run(
            nfcListPath,
            ['-v'],
            environment: {'LIBNFC_DEVICE': 'pn532_uart:$port'},
            runInShell: true,
          ).timeout(Duration(seconds: 2));
          
          if (testResult.exitCode == 0 && 
              (testResult.stdout as String).contains('NFC device:')) {
            print('✅ Device found on $port');
            return port;
          }
        } catch (e) {
          continue;
        }
      }
      return null;
    } catch (e) {
      print('Error finding COM port: $e');
      return null;
    }
  }
  
  Future<Map<String, String>> _getEnv() async {
    _cachedComPort ??= await _findComPort();
    if (_cachedComPort == null) {
      throw Exception('NFC device not found');
    }
    return {'LIBNFC_DEVICE': 'pn532_uart:${_cachedComPort!}'};
  }
  
  Future<String?> readUid() async {
    try {
      final env = await _getEnv();
      final result = await Process.run(
        nfcListPath, 
        ['-v'],
        environment: env,
        runInShell: true,
      ).timeout(Duration(seconds: 5));
      
      if (result.exitCode != 0) return null;
      final output = result.stdout as String;
      return _parseUid(output);
    } catch (e) {
      return null;
    }
  }
  
  // Прочитать баланс с карты
  Future<int?> readBalance() async {
    try {
      final env = await _getEnv();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('temp_$timestamp.bin');
      
      final result = await Process.run(
        nfcMfClassicPath,
        ['r', defaultKey, 'u', tempFile.path],
        environment: env,
        runInShell: true,
      ).timeout(Duration(seconds: 10));
      
      if (result.exitCode == 0 && await tempFile.exists()) {
        final bytes = await tempFile.readAsBytes();
        await tempFile.delete();
        
        if (bytes.length >= 68) {
          // Баланс в блоке 4 (байты 64-67)
          final balance = bytes[64] | 
                          (bytes[65] << 8) | 
                          (bytes[66] << 16) | 
                          (bytes[67] << 24);
          return balance;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Записать баланс на карту
  Future<bool> writeBalance(int balance) async {
    try {
      final env = await _getEnv();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('temp_$timestamp.bin');
      
      // Читаем текущий дамп
      final readResult = await Process.run(
        nfcMfClassicPath,
        ['r', defaultKey, 'u', tempFile.path],
        environment: env,
        runInShell: true,
      ).timeout(Duration(seconds: 10));
      
      List<int> bytes;
      if (readResult.exitCode == 0 && await tempFile.exists()) {
        bytes = await tempFile.readAsBytes();
      } else {
        bytes = List.filled(1024, 0);
      }
      
      if (bytes.length >= 68) {
        // Обновляем ТОЛЬКО баланс
        bytes[64] = balance & 0xFF;
        bytes[65] = (balance >> 8) & 0xFF;
        bytes[66] = (balance >> 16) & 0xFF;
        bytes[67] = (balance >> 24) & 0xFF;
        
        await tempFile.writeAsBytes(bytes);
        
        final writeResult = await Process.run(
          nfcMfClassicPath,
          ['w', defaultKey, 'u', tempFile.path],
          environment: env,
          runInShell: true,
        ).timeout(Duration(seconds: 10));
        
        await tempFile.delete();
        return writeResult.exitCode == 0;
      }
      
      await tempFile.delete();
      return false;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
  
  String? _parseUid(String output) {
    final lines = output.split('\n');
    for (final line in lines) {
      if (line.contains('UID (NFCID1):')) {
        final match = RegExp(r'UID \(NFCID1\):\s*([A-F0-9\s]+)', caseSensitive: false)
            .firstMatch(line);
        if (match != null) {
          return match.group(1)?.trim();
        }
      }
    }
    return null;
  }
}