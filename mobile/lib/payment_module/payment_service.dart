import '../services/api_client.dart';

class PaymentService {
  // Get payment dashboard summary.
  Future<Map<String, dynamic>> getSummary(String groupId) {
    return api.get(
      '/payments/summary',
      query: {'groupId': groupId},
    );
  }

  // Record a new payment.
  Future<Map<String, dynamic>> recordPayment({
    required String groupId,
    required String memberId,
    required double amount,
    required String month,
    required DateTime date,
    String method = 'Cash',
    String reference = '',
  }) {
    final paymentDate = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return api.post('/payments', {
      'groupId': groupId,
      'memberId': memberId,
      'amount': amount,
      'month': month,
      'date': paymentDate,
      'method': method,
      'reference': reference,
    });
  }

  // Get payment history.
  Future<Map<String, dynamic>> getHistory(String groupId) {
    return api.get(
      '/payments/history',
      query: {'groupId': groupId},
    );
  }

  // Get shared payment records for a month.
  Future<Map<String, dynamic>> getSharedRecords({
    required String groupId,
    required String month,
  }) {
    return api.get(
      '/payments/shared',
      query: {
        'groupId': groupId,
        'month': month,
      },
    );
  }
}

final paymentService = PaymentService();
