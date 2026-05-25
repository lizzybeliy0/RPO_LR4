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
  bool _showSuccess = false;
  bool _showError = false;
  bool _showTimeout = false;
  Timer? _messageTimer;

  void _showTemporaryMessage(String message, {bool isSuccess = false, bool isError = false, bool isTimeout = false}) {
    setState(() {
      _status = message;
      _showSuccess = isSuccess;
      _showError = isError;
      _showTimeout = isTimeout;
    });
    
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _showSuccess = false;
        _showError = false;
        _showTimeout = false;
        _status = 'Готов к оплате';
        _cardOwner = null;
        _balance = null;
      });
    });
  }

  Future<void> _startPayment() async {
    if (_isWaiting) return;

    setState(() {
      _isWaiting = true;
      _remainingSeconds = 30;
      _status = 'Приложите карту...';
      _showSuccess = false;
      _showError = false;
      _showTimeout = false;
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
          _showTemporaryMessage('Карта не зарегистрирована', isError: true);
          setState(() {
            _isWaiting = false;
          });
          return;
        }
        
        final success = await widget.paymentService.pay(uid, 50, 1);  // terminalId = 1
        
        if (success) {
          final updatedCard = widget.paymentService.getCard(uid);
          setState(() {
            _cardOwner = updatedCard?.ownerName;
            _balance = updatedCard?.balance;
          });
          _showTemporaryMessage('Оплачено 50 руб.', isSuccess: true);
          setState(() {
            _isWaiting = false;
          });
        } else {
          _showTemporaryMessage('Недостаточно средств', isError: true);
          setState(() {
            _isWaiting = false;
          });
        }
        return;
      }
      
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _cancelPayment() {
    _showTemporaryMessage('Время истекло. Попробуйте снова', isTimeout: true);
    setState(() {
      _isWaiting = false;
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
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
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: SizedBox(
                  width: 360,  // ← фиксированная ширина, как у карточки входа
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2e7d32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Приложите карту к считывателю',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Информация об успешной оплате
                          if (_showSuccess && _cardOwner != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF2e7d32), size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_cardOwner',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Баланс: $_balance руб.',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Статус
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _isWaiting 
                                  ? Colors.orange[50] 
                                  : (_showSuccess ? Colors.green[50] : (_showError || _showTimeout ? Colors.red[50] : Colors.grey[100])),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isWaiting 
                                    ? Colors.orange[200]! 
                                    : (_showSuccess ? Colors.green[200]! : (_showError || _showTimeout ? Colors.red[200]! : Colors.grey[300]!)),
                              ),
                            ),
                            child: Text(
                              _status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _isWaiting ? FontWeight.bold : FontWeight.normal,
                                color: _isWaiting ? Colors.orange[800] : (_showSuccess ? Colors.green[800] : (_showError || _showTimeout ? Colors.red[800] : Colors.grey[700])),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 28),
                          
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
        ),
      ),
    );
  }
}