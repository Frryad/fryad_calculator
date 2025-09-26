import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart'; // To access notifiers
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'helpers/export_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.menuHeader),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Consumer<ThemeNotifier>(
            builder: (context, theme, child) => SwitchListTile(
              title: Text(loc.darkMode),
              value: theme.themeMode == ThemeMode.dark,
              onChanged: (value) => theme.toggleTheme(),
              secondary: const Icon(Icons.brightness_6),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(loc.language, style: Theme.of(context).textTheme.titleMedium),
          ),
          Consumer<LocaleNotifier>(
            builder: (context, localeNotifier, child) {
              final currentLocale = localeNotifier.locale?.languageCode ?? Localizations.localeOf(context).languageCode;
              return Column(
                children: [
                  RadioListTile<String>(
                    title: const Text("English"),
                    value: "en",
                    groupValue: currentLocale,
                    onChanged: (val) => localeNotifier.setLocale(Locale(val!)),
                  ),
                  RadioListTile<String>(
                    title: const Text("کوردی سۆرانی"),
                    value: "ckb", 
                    groupValue: currentLocale,
                    onChanged: (val) => localeNotifier.setLocale(Locale(val!)),
                  ),
                  RadioListTile<String>(
                    title: const Text("العربية"),
                    value: "ar",
                    groupValue: currentLocale,
                    onChanged: (val) => localeNotifier.setLocale(Locale(val!)),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Data Management", style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text("Export to CSV"),
            subtitle: const Text("Share a spreadsheet of your expenses"),
            onTap: () async {
              await ExportService().exportToCsv();
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text("Backup Database (.db)"),
            subtitle: const Text("Share the raw database file"),
            onTap: () async {
              await ExportService().exportToSql();
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text("Import from CSV"),
            subtitle: const Text("WARNING: Replaces all current data"),
            onTap: () async {
              await ExportService().importFromCsv();
            },
          ),
        ],
      ),
    );
  }
}