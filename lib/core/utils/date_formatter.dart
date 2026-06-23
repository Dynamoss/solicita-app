import 'package:intl/intl.dart';

/// Small date helpers kept in one place so formatting is consistent app-wide.
abstract final class DateFormatter {
  static final DateFormat _full = DateFormat('dd/MM/yyyy • HH:mm', 'pt_BR');

  static String full(DateTime date) => _full.format(date.toLocal());

  /// Human, relative description ("há 5 min", "ontem", ...) for list items.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date.toLocal());

    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    return _full.format(date.toLocal());
  }
}
