import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Locale-aware date/time formatting for UI display.
abstract final class AppDateFormat {
  static String mediumDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  static String shortTime(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.Hm(locale).format(date);
  }

  static String mediumDateTime(BuildContext context, DateTime date) {
    return '${mediumDate(context, date)} · ${shortTime(context, date)}';
  }
}
