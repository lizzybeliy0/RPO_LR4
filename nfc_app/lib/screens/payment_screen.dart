// screens/payment_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../nfc_service.dart';
import '../payment_service.dart';
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
  int _remainingSeconds = 15; // 15 секунд на операцию
  String _status = 'Готов к оплате';
  String? _cardOwner;
  int? _balance;
  bool _showSuccess = false;
  bool _showError = false;
  bool _showTimeout = false;
  Timer? _messageTimer;
  Timer? _countdownTimer;

  void _showTemporaryMessage(String message, {bool isSuccess = false, bool isError = false, bool isTimeout = false}) {
    setState(() {
      _status = message;
      _showSuccess = isSuccess;
      _showError = isError;
      _showTimeout = isTimeout;
    });
    
    _messageTimer?.cancel();
    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSuccess = false;
          _showError = false;
          _showTimeout = false;
          _status = 'Готов к оплате';
          _cardOwner = null;
          _balance = null;
        });
      }
    });
  }

  Future<void> _startPayment() async {
    if (_isWaiting) return;
    await _processTransaction(() => widget.paymentService.pay(), 50, 'оплаты');
  }

  Future<void> _startReplenish() async {
    if (_isWaiting) return;
    await _processTransaction(() => widget.paymentService.replenish(), 500, 'пополнения');
  }

  Future<void> _startSync() async {
    if (_isWaiting) return;
    await _processTransaction(() => widget.paymentService.syncWithBackend(), 0, 'синхронизации');
  }

  Future<void> _processTransaction(Future<bool> Function() transaction, int amount, String actionName) async {
    if (!mounted) return;
    
    setState(() {
      _isWaiting = true;
      _remainingSeconds = 15;
      _status = 'Приложите карту для $actionName...';
      _showSuccess = false;
      _showError = false;
      _showTimeout = false;
    });

    // Таймер обратного отсчета
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        _status = 'Приложите карту для $actionName... (${_remainingSeconds}с)';
      });
      if (_remainingSeconds <= 0) {
        t.cancel();
        _cancelOperation();
      }
    });

    // Пытаемся выполнить операцию в течение 15 секунд
    bool success = false;
    for (int i = 0; i < 15 && _remainingSeconds > 0; i++) {
      success = await transaction();
      if (success) break;
      await Future.delayed(const Duration(seconds: 1));
    }
    
    _countdownTimer?.cancel();
    
    if (!mounted) return;
    
    if (success) {
      final info = await widget.paymentService.getCardInfo();
      if (mounted) {
        setState(() {
          _cardOwner = info.$2;
          _balance = info.$3;
        });
        
        String message;
        if (actionName == 'синхронизации') {
          message = 'Синхронизация выполнена! Баланс: ${info.$3} руб.';
        } else {
          message = amount == 50 ? 'Оплачено $amount руб.' : 'Пополнено $amount руб.';
        }
        
        _showTemporaryMessage(message, isSuccess: true);
        setState(() { _isWaiting = false; });
      }
    } else {
      _showTemporaryMessage('Операция не удалась. Попробуйте снова', isError: true);
      setState(() { _isWaiting = false; });
    }
  }

  void _cancelOperation() {
    if (mounted) {
      _showTemporaryMessage('Время истекло. Попробуйте снова', isTimeout: true);
      setState(() {
        _isWaiting = false;
      });
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _countdownTimer?.cancel();
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
                  width: 360,
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
                          
                          // Три кнопки: Оплата, Пополнение, Синхронизация
                          Column(
                            children: [
                              PaymentButton(
                                isLoading: _isWaiting,
                                onPayPressed: _startPayment,
                                onReplenishPressed: _startReplenish,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isWaiting ? null : _startSync,
                                  icon: const Icon(Icons.sync, color: Colors.white),
                                  label: const Text(
                                    'СИНХРОНИЗИРОВАТЬ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9C27B0),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    disabledBackgroundColor: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ],
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