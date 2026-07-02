class DateUtils {
  DateUtils._();

  static String today() {
    final now = DateTime.now();
    return _formatDate(now);
  }

  static String currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String monthStart(String yearMonth) {
    return '$yearMonth-01';
  }

  static String monthEnd(String yearMonth) {
    final parts = yearMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final lastDay = DateTime(year, month + 1, 0).day;
    final dayStr = lastDay.toString().padLeft(2, '0');
    return '$yearMonth-$dayStr';
  }

  static String yearStart(String year) {
    return '$year-01-01';
  }

  static String yearEnd(String year) {
    return '$year-12-31';
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatDateDisplay(String dateStr) {
    // Convert YYYY-MM-DD to display format like "6月30日"
    try {
      final parts = dateStr.split('-');
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      return '${month}月${day}日';
    } catch (_) {
      return dateStr;
    }
  }

  static String formatMonthDisplay(String yearMonth) {
    try {
      final parts = yearMonth.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      return '${year}年${month}月';
    } catch (_) {
      return yearMonth;
    }
  }

  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
