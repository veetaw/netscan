import 'package:flutter/material.dart';
import 'catalog.dart';

String tr(
  BuildContext context,
  String key, [
  Map<String, Object?> values = const {},
]) => translate(Localizations.localeOf(context).languageCode, key, values);

String translate(
  String language,
  String key, [
  Map<String, Object?> values = const {},
]) {
  var value =
      (language == 'it' ? italian[key] : english[key]) ?? english[key] ?? key;
  for (final entry in values.entries) {
    value = value.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
  }
  return value;
}
