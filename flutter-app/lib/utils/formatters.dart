import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ar_SA',
    symbol: 'ر.س',
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,###');

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'ar');

  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} مليون ر.س';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} ألف ر.س';
    }
    return _currencyFormat.format(amount);
  }

  static String formatNumber(int number) {
    return _numberFormat.format(number);
  }

  static String formatOdometer(int km) {
    return '${_numberFormat.format(km)} كم';
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  static String getDayName(DateTime date) {
    const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return days[date.weekday % 7];
  }

  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    if (diff == -1) return 'غداً';
    if (diff > 0 && diff < 7) return 'منذ $diff أيام';
    if (diff < 0 && diff > -7) return 'بعد ${-diff} أيام';
    return _dateFormat.format(date);
  }

  static String getRemainingDays(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) return 'متأخر ${-diff} يوم';
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff <= 7) return 'بعد $diff أيام';
    if (diff <= 30) return 'بعد ${(diff / 7).floor()} أسبوع';
    return 'بعد ${(diff / 30).floor()} شهر';
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}
