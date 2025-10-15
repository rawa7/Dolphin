import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  
  static Future<Locale> getSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    return Locale(languageCode);
  }
  
  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
  
  static List<LocaleInfo> getSupportedLanguages() {
    return [
      LocaleInfo(locale: const Locale('en'), name: 'English', nativeName: 'English'),
      LocaleInfo(locale: const Locale('ar'), name: 'Arabic', nativeName: 'العربية'),
      LocaleInfo(locale: const Locale('fa'), name: 'Kurdish', nativeName: 'کوردی'), // Using 'fa' for Kurdish Sorani
    ];
  }
}

class LocaleInfo {
  final Locale locale;
  final String name;
  final String nativeName;
  
  LocaleInfo({
    required this.locale,
    required this.name,
    required this.nativeName,
  });
}

