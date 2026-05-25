import 'dart:async';
import 'package:flutter/material.dart';
import 'nfc_service.dart';
import 'payment_service.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final paymentService = PaymentService();
  await paymentService.load();
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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: PaymentScreen(paymentService: paymentService),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final PaymentService paymentService;
  const PaymentScreen({super.key, required this.paymentService});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final NfcService _nfc = NfcService();
  bool _isWaiting = false;
  int _remainingSeconds = 30;
  String _status = 'Готов к оплате';
  String? _cardOwner;
  int? _balance;
  bool _paymentSuccess = false;

  Future<void> _startPayment() async {
    if (_isWaiting) return;

    setState(() {
      _isWaiting = true;
      _remainingSeconds = 30;
      _status = 'Приложите карту...';
      _paymentSuccess = false;
    });

    // Таймер обратного отсчёта
    Timer? timer;
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      setState(() {
        _remainingSeconds--;
        _status = 'Приложите карту... (${_remainingSeconds}с)';
      });
      if (_remainingSeconds <= 0) {
        t.cancel();
        _cancelPayment();
      }
    });

    // Ждём карту (максимум 30 попыток)
    for (int i = 0; i < 30 && _remainingSeconds > 0; i++) {
      final uid = await _nfc.readCardUid();
      
      if (uid != null) {
        timer?.cancel();
        final card = widget.paymentService.getCard(uid);
        
        if (card == null) {
          setState(() {
            _status = '❌ Карта не зарегистрирована';
            _isWaiting = false;
          });
          return;
        }
        
        final success = await widget.paymentService.pay(uid, 50);
        
        if (success) {
          final updatedCard = widget.paymentService.getCard(uid);
          setState(() {
            _cardOwner = updatedCard?.ownerName;
            _balance = updatedCard?.balance;
            _status = '✅ Оплачено 50 руб.';
            _paymentSuccess = true;
            _isWaiting = false;
          });
        } else {
          setState(() {
            _status = '❌ Недостаточно средств';
            _isWaiting = false;
          });
        }
        return;
      }
      
      await Future.delayed(Duration(seconds: 1));
    }
  }

  void _cancelPayment() {
    setState(() {
      _status = '⏰ Время истекло';
      _isWaiting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Кошелек'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Информация о последней оплате
            if (_cardOwner != null && _paymentSuccess) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        '$_cardOwner',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Баланс: $_balance руб.',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Статус
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isWaiting 
                    ? Colors.orange[100] 
                    : (_paymentSuccess ? Colors.green[100] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: _isWaiting ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Кнопка оплаты
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton(
                onPressed: _isWaiting ? null : _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isWaiting ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isWaiting ? 'ОПЛАТА...' : 'ПРОИЗВЕСТИ ОПЛАТУ',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}