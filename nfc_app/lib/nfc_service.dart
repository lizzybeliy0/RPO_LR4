// nfc_service.dart
import 'dart:io';

class NfcService {
  final String nfcListPath = r'C:\Users\Lizaveta\MGTU_Study\rpo2\lab4\libs\libnfc\build\utils\nfc-list.exe';
  String? _cachedComPort;

  Future<String?> _findComPort() async {
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
      final testResult = await Process.run(
        nfcListPath,
        ['-v'],
        environment: {'LIBNFC_DEVICE': 'pn532_uart:$port'},
        runInShell: true,
      );
      
      if (testResult.exitCode == 0 && (testResult.stdout as String).contains('NFC device:')) {
        print('✅ Device found on $port');
        return port;
      }
    }
    return null;
  }

  Future<String?> readCardUid({int maxAttempts = 15}) async {
    _cachedComPort ??= await _findComPort();
    if (_cachedComPort == null) {
      print('❌ NFC device not found');
      return null;
    }
    
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final result = await Process.run(
          nfcListPath,
          ['-v'],
          environment: {'LIBNFC_DEVICE': 'pn532_uart:$_cachedComPort'},
          runInShell: true,
        );
        
        if (result.exitCode == 0) {
          final output = result.stdout as String;
          final uid = _parseUid(output);
          if (uid != null) {
            return uid;
          }
        }
        
        await Future.delayed(Duration(seconds: 1));
        print('Waiting for card... (${i + 1}/$maxAttempts)');
        
      } catch (e) {
        print('NFC error: $e');
      }
    }
    
    print('No card detected after $maxAttempts attempts');
    return null;
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