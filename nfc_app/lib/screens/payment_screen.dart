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
  bool _isProcessing = false;
  int _remainingSeconds = 40;
  String _status = 'Готов к оплате';
  String? _cardOwner;
  int? _balance;
  bool _showSuccess = false;
  bool _showError = false;
  bool _showTimeout = false;
  Timer? _messageTimer;
  Timer? _countdownTimer;
  bool _operationCompleted = false;
  String? _currentActionName;

  void _showMessage(String message, {bool isSuccess = false, bool isError = false, bool isTimeout = false}) {
    if (!mounted) return;
    
    setState(() {
      _status = message;
      _showSuccess = isSuccess;
      _showError = isError;
      _showTimeout = isTimeout;
      _isWaiting = false;
      _isProcessing = false;
      _operationCompleted = true;
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
    _currentActionName = 'оплаты';
    await _processTransaction(() => widget.paymentService.pay(), 50);
  }

  Future<void> _startReplenish() async {
    if (_isWaiting) return;
    _currentActionName = 'пополнения';
    await _processTransaction(() => widget.paymentService.replenish(), 500);
  }

  Future<void> _startSync() async {
    if (_isWaiting) return;
    _currentActionName = 'синхронизации';
    await _processTransaction(() async {
      final success = await widget.paymentService.syncWithBackend();
      return success ? null : '❌ Ошибка синхронизации';
    }, 0);
  }

  Future<void> _processTransaction(Future<String?> Function() transaction, int amount) async {
    if (!mounted) return;
    
    _operationCompleted = false;
    
    setState(() {
      _isWaiting = true;
      _isProcessing = false;
      _remainingSeconds = 40;
      _status = 'Приложите карту для ${_currentActionName}...';
      _showSuccess = false;
      _showError = false;
      _showTimeout = false;
    });

    // Устанавливаем колбэк для уведомления о начале операции
    widget.paymentService.onCardDetected = () {
      if (mounted && !_operationCompleted) {
        setState(() {
          _isProcessing = true;
          _isWaiting = false;
          _status = '💳 ${_currentActionName == 'оплаты' ? 'Оплата' : (_currentActionName == 'пополнения' ? 'Пополнение' : 'Синхронизация')} выполняется...\nНЕ УБИРАЙТЕ КАРТУ!';
        });
        _countdownTimer?.cancel();
      }
    };
    
    // Таймер ожидания карты
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _isProcessing || _operationCompleted) {
        t.cancel();
        return;
      }
      
      setState(() {
        if (_remainingSeconds > 0 && !_isProcessing && !_operationCompleted) {
          _remainingSeconds--;
          _status = 'Приложите карту для ${_currentActionName}... (${_remainingSeconds}с)';
        }
      });
      
      if (_remainingSeconds <= 0 && !_isProcessing && !_operationCompleted) {
        t.cancel();
        if (mounted) {
          _operationCompleted = true;
          _showMessage('⏰ Время истекло. Попробуйте снова', isTimeout: true);
        }
      }
    });

    // Запускаем операцию
    String? errorMessage = await transaction();
    
    // Очищаем колбэк
    widget.paymentService.onCardDetected = null;
    
    _operationCompleted = true;
    _countdownTimer?.cancel();
    
    if (mounted) {
      if (errorMessage == null) {
        final info = await widget.paymentService.getCardInfo();
        setState(() {
          _cardOwner = info.$2;
          _balance = info.$3;
        });
        
        String message;
        if (_currentActionName == 'синхронизации') {
          message = '✅ Синхронизация выполнена! Баланс: ${info.$3} руб.';
        } else {
          message = '✅ ${_currentActionName == 'оплаты' ? 'Оплачено' : 'Пополнено'} $amount руб. Баланс: ${info.$3} руб.';
        }
        
        _showMessage(message, isSuccess: true);
      } else {
        _showMessage(errorMessage, isError: true);
      }
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _countdownTimer?.cancel();
    widget.paymentService.onCardDetected = null;
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
                          
                          if (_showSuccess) ...[
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
                                  if (_cardOwner != null) Text(
                                    _cardOwner!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _status,
                                    style: const TextStyle(fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          if (_showError) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red[700], size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _status,
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          if (_showTimeout) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.timer, color: Colors.orange[700], size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _status,
                                      style: TextStyle(color: Colors.orange[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          if (!_showSuccess && !_showError && !_showTimeout) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: (_isWaiting || _isProcessing) ? Colors.orange[50] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (_isWaiting || _isProcessing) ? Colors.orange[200]! : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (_isProcessing)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  if (_isProcessing) const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _status,
                                      textAlign: _isProcessing ? TextAlign.left : TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: (_isWaiting || _isProcessing) ? FontWeight.bold : FontWeight.normal,
                                        color: (_isWaiting || _isProcessing) ? Colors.orange[800] : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          const SizedBox(height: 28),
                          
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