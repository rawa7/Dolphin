import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import '../services/language_service.dart';
import '../main.dart';

class LanguageSelectorScreen extends StatelessWidget {
  const LanguageSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languages = LanguageService.getSupportedLanguages();
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
        backgroundColor: const Color(0xFF9C1B5E),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final language = languages[index];
          final isSelected = currentLocale.languageCode == language.locale.languageCode;

          return ListTile(
            leading: Icon(
              Icons.language,
              color: isSelected ? const Color(0xFF9C1B5E) : Colors.grey,
            ),
            title: Text(
              language.nativeName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF9C1B5E) : Colors.black,
              ),
            ),
            subtitle: Text(language.name),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Color(0xFF9C1B5E))
                : null,
            onTap: () async {
              await LanguageService.setLanguage(language.locale.languageCode);
              if (context.mounted) {
                MyApp.of(context)?.setLocale(language.locale);
                Navigator.pop(context);
              }
            },
          );
        },
      ),
    );
  }
}

