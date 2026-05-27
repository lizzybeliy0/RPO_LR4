import 'package:flutter/material.dart';
import 'payment_service.dart';
import 'screens/payment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final paymentService = PaymentService();
  // load() больше не нужен, данные читаются напрямую с карты
  runApp(MyApp(paymentService: paymentService));
}

class MyApp extends StatelessWidget {
  final PaymentService paymentService;
  const MyApp({super.key, required this.paymentService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFC Кошелек',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: PaymentScreen(paymentService: paymentService),
      debugShowCheckedModeBanner: false,
    );
  }
}