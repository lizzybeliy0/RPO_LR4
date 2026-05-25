import 'dart:async';
import 'package:flutter/material.dart';
import '../nfc_service.dart';
import '../payment_service.dart';
import '../models.dart';
import '../widgets/payment_button.dart';

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

    Timer? timer;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _remainingSeconds--;
        _status = 'Приложите карту... (${_remainingSeconds}с)';
      });
      if (_remainingSeconds <= 0) {
        t.cancel();
        _cancelPayment();
      }
    });

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
      
      await Future.delayed(const Duration(seconds: 1));
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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/tram.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'NFC Кошелек',
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Заголовок
                      const Text(
                        'ОПЛАТА ПРОЕЗДА',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2e7d32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Приложите карту к считывателю',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      
                      // Информация о последней оплате
                      if (_cardOwner != null && _paymentSuccess) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF2e7d32), size: 48),
                              const SizedBox(height: 8),
                              Text(
                                '$_cardOwner',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Баланс: $_balance руб.',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
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
                              ? Colors.orange[50] 
                              : (_paymentSuccess ? Colors.green[50] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isWaiting 
                                ? Colors.orange[200]! 
                                : (_paymentSuccess ? Colors.green[200]! : Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: _isWaiting ? FontWeight.bold : FontWeight.normal,
                            color: _isWaiting ? Colors.orange[800] : (_paymentSuccess ? Colors.green[800] : Colors.grey[700]),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Кнопка оплаты
                      PaymentButton(
                        isLoading: _isWaiting,
                        onPressed: _startPayment,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}