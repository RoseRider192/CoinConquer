import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');
  static final NumberFormat _compactFormat = NumberFormat.compact();

  static String formatAmount(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatAmountCompact(double amount) {
    return _compactFormat.format(amount);
  }

  static String formatIncome(double amount) {
    return '+¥${_currencyFormat.format(amount)}';
  }

  static String formatExpense(double amount) {
    return '-¥${_currencyFormat.format(amount)}';
  }

  static String formatAmountSigned(String type, double amount) {
    if (type == 'income') {
      return '+¥${_currencyFormat.format(amount)}';
    }
    return '-¥${_currencyFormat.format(amount)}';
  }
}
