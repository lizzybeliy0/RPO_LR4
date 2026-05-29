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
      ).timeout(Duration(seconds: 30));

      await Future.delayed(Duration(milliseconds: 500));
      
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
  

  Future<bool> writeBalance(int balance) async {
    try {
      print('     Writing balance $balance to card...');
      final env = await _getEnv();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('temp_$timestamp.bin');
      
      // Читаем текущий дамп
      final readResult = await Process.run(
        nfcMfClassicPath,
        ['r', defaultKey, 'u', tempFile.path],
        environment: env,
        runInShell: true,
      ).timeout(Duration(seconds: 30));

      await Future.delayed(Duration(milliseconds: 500));
      
      if (readResult.exitCode != 0) {
        print('   Failed to read card (exitCode=${readResult.exitCode})');
        print('   Error: ${readResult.stderr}');
        await tempFile.delete();
        return false;
      }
      
      if (!await tempFile.exists()) {
        print('   Dump file not created');
        return false;
      }
      
      final bytes = await tempFile.readAsBytes();
      print('   Read existing dump, size: ${bytes.length} bytes');
      
      if (bytes.length < 68) {
        print('   Dump too small: ${bytes.length} bytes');
        await tempFile.delete();
        return false;
      }
      
      final oldBalance = bytes[64] | (bytes[65] << 8) | (bytes[66] << 16) | (bytes[67] << 24);
      print('   Old balance from dump: $oldBalance');
      
      if (bytes.length >= 68) {
        // Обновляем баланс
        bytes[64] = balance & 0xFF;
        bytes[65] = (balance >> 8) & 0xFF;
        bytes[66] = (balance >> 16) & 0xFF;
        bytes[67] = (balance >> 24) & 0xFF;
        
        print('   New balance bytes: ${bytes[64]} ${bytes[65]} ${bytes[66]} ${bytes[67]}');
        
        await tempFile.writeAsBytes(bytes);
        
        // Записываем на карту
        final writeResult = await Process.run(
          nfcMfClassicPath,
          ['w', defaultKey, 'u', tempFile.path],
          environment: env,
          runInShell: true,
        ).timeout(Duration(seconds: 30));
        
        if (writeResult.exitCode == 0) {
          print('   !!!Write successful!');
          
          // ПРОВЕРЯЕМ: читаем баланс сразу после записи
          await Future.delayed(Duration(milliseconds: 500));
          final verifyBalance = await readBalance();
          print('   Verification read: $verifyBalance RUB');
          
          if (verifyBalance == balance) {
            print('   !!!Balance verified!');
            await tempFile.delete();
            return true;
          } else {
            print('   Balance verification FAILED! Expected $balance, got $verifyBalance');
            await tempFile.delete();
            return false;
          }
        } else {
          print('   Write failed with exit code: ${writeResult.exitCode}');
          print('   Error: ${writeResult.stderr}');
          await tempFile.delete();
          return false;
        }
      }
      
      await tempFile.delete();
      return false;
    } catch (e) {
      print('   Error writing balance: $e');
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