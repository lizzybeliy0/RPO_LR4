import 'package:flutter/foundation.dart';

void main() {
  if (kReleaseMode) {
    // В релизной версии ничего не выводим
  } else {
    // ignore: avoid_print
    print('Flutter приложение требует Visual Studio. Запустите: dart run bin/console.dart');
  }
}