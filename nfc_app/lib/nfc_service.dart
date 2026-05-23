import 'dart:io';

class NfcService {
  final String nfcListPath = r'C:\Users\Lizaveta\MGTU_Study\rpo2\lab4\libs\libnfc\build\utils\nfc-list.exe';

  Future<String?> readCardUid({int maxAttempts = 30}) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        final result = await Process.run(
          nfcListPath,
          ['-v'],
        );
        
        if (result.exitCode == 0) {
          final output = result.stdout as String;
          final uid = _parseUid(output);
          if (uid != null) {
            print('Card detected! UID: $uid');
            return uid;
          }
        }
        
        // Ждём 1 секунду перед следующим сканированием
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