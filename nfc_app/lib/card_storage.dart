// lib/card_storage.dart
import 'dart:io';
import 'dart:convert';

class UpdateResult {
  final bool success;
  final int? newBalance;
  final String? error;
  
  UpdateResult({required this.success, this.newBalance, this.error});
  
  factory UpdateResult.ok(int balance) => 
      UpdateResult(success: true, newBalance: balance, error: null);
  
  factory UpdateResult.insufficientFunds(int oldBalance) => 
      UpdateResult(
        success: false, 
        newBalance: null, 
        error: 'Недостаточно средств! Баланс: $oldBalance руб.'
      );
  
  factory UpdateResult.readError() => 
      UpdateResult(
        success: false, 
        newBalance: null, 
        error: 'Не удалось прочитать карту. Проверьте, что карта приложена.'
      );
  
  factory UpdateResult.writeError() => 
      UpdateResult(
        success: false, 
        newBalance: null, 
        error: 'Ошибка при записи на карту. Попробуйте снова.'
      );
}

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
          ).timeout(Duration(seconds: 30));
          
          if (testResult.exitCode == 0 && 
              (testResult.stdout as String).contains('NFC device:')) {
            print('   Device found on $port');
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
      ).timeout(Duration(seconds: 30));
      
      if (result.exitCode != 0) return null;
      final output = result.stdout as String;
      return _parseUid(output);
    } catch (e) {
      return null;
    }
  }
  
  // Прочитать баланс с карты (без изменения)
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
      ).timeout(Duration(seconds: 30));

      await Future.delayed(Duration(milliseconds: 500));
      
      if (result.exitCode == 0 && await tempFile.exists()) {
        final bytes = await tempFile.readAsBytes();
        if (await tempFile.exists()) await tempFile.delete();
        
        if (bytes.length >= 68) {
          final balance = bytes[64] | (bytes[65] << 8) | (bytes[66] << 16) | (bytes[67] << 24);
          return balance;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Записать конкретный баланс на карту (для инициализации и синхронизации)
  Future<bool> writeBalance(int balance) async {
    try {
      print('     Writing balance $balance to card...');
      final env = await _getEnv();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('temp_$timestamp.bin');
      
      final readResult = await Process.run(
        nfcMfClassicPath,
        ['r', defaultKey, 'u', tempFile.path],
        environment: env,
        runInShell: true,
      ).timeout(Duration(seconds: 30));

      await Future.delayed(Duration(milliseconds: 500));
      
      if (readResult.exitCode != 0) {
        print('   Failed to read card');
        if (await tempFile.exists()) await tempFile.delete();
        return false;
      }
      
      if (!await tempFile.exists()) {
        print('   Dump file not created');
        return false;
      }
      
      final bytes = await tempFile.readAsBytes();
      
      if (bytes.length < 68) {
        print('   Dump too small');
        if (await tempFile.exists()) await tempFile.delete();
        return false;
      }
      
      final oldBalance = bytes[64] | (bytes[65] << 8) | (bytes[66] << 16) | (bytes[67] << 24);
      print('   Old balance: $oldBalance → New balance: $balance');
      
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
      ).timeout(Duration(seconds: 30));
      
      if (await tempFile.exists()) await tempFile.delete();
      
      if (writeResult.exitCode == 0) {
        print('   ✅ Balance written successfully!');
        return true;
      } else {
        print('   Write failed');
        return false;
      }
    } catch (e) {
      print('   Error writing balance: $e');
      return false;
    }
  }

  Future<UpdateResult> updateBalance(int delta) async {
    try {
      print('     Updating balance by $delta...');
      final env = await _getEnv();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('temp_$timestamp.bin');
      
      final readResult = await Process.run(
        nfcMfClassicPath,
        ['r', defaultKey, 'u', tempFile.path],
        environment: env,
        runInShell: true,
      ).timeout(Duration(seconds: 30));

      await Future.delayed(Duration(milliseconds: 500));
      
      if (readResult.exitCode != 0) {
        if (await tempFile.exists()) await tempFile.delete();
        return UpdateResult.readError();
      }
      
      if (!await tempFile.exists()) {
        return UpdateResult.readError();
      }
      
      final bytes = await tempFile.readAsBytes();
      
      if (bytes.length < 68) {
        if (await tempFile.exists()) await tempFile.delete();
        return UpdateResult.readError();
      }
      
      final oldBalance = bytes[64] | (bytes[65] << 8) | (bytes[66] << 16) | (bytes[67] << 24);
      final newBalance = oldBalance + delta;
      
      // Проверка на недостаточность средств
      if (newBalance < 0) {
        if (await tempFile.exists()) await tempFile.delete();
        return UpdateResult.insufficientFunds(oldBalance);
      }
      
      print('   Old balance: $oldBalance → New balance: $newBalance');
      
      //1 блок из 4 сектора 1 из 16 (1 блок 64 байта)
      bytes[64] = newBalance & 0xFF;
      bytes[65] = (newBalance >> 8) & 0xFF;
      bytes[66] = (newBalance >> 16) & 0xFF;
      bytes[67] = (newBalance >> 24) & 0xFF;
      
      await tempFile.writeAsBytes(bytes);
      
      final writeResult = await Process.run(
        nfcMfClassicPath,
        ['w', defaultKey, 'u', tempFile.path],
        environment: env,
        runInShell: true,
      ).timeout(Duration(seconds: 30));
      
      if (await tempFile.exists()) await tempFile.delete();
      
      if (writeResult.exitCode == 0) {
        print('   ✅ Balance updated successfully! New balance: $newBalance');
        return UpdateResult.ok(newBalance);
      } else {
        return UpdateResult.writeError();
      }
    } catch (e) {
      print('   Error updating balance: $e');
      return UpdateResult.readError();
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