import 'dart:io';

void main() async {
  final nfcPath = r'C:\Users\Lizaveta\MGTU_Study\rpo2\lab4\libs\libnfc\build\utils\nfc-list.exe';
  final comPort = 'COM6';
  
  print('Тест NFC: запускаем $nfcPath');
  
  try {
    final result = await Process.run(
      nfcPath,
      ['pn532_uart:$comPort', '-v'],
    );
    
    print('Exit code: ${result.exitCode}');
    print('STDOUT:');
    print(result.stdout);
    print('STDERR:');
    print(result.stderr);
  } catch (e) {
    print('Ошибка: $e');
  }
}