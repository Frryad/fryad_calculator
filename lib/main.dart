import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'themes.dart';
import 'pages/profiles_list_page.dart';
import 'pages/wishlist_page.dart';
import 'pages/calculator_page.dart';
import 'pages/budgets_page.dart';
import 'pages/reports_page.dart';

// --- State Management Notifiers ---
class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode;
  ThemeNotifier(this._themeMode);
  get themeMode => _themeMode;

  void toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}

class LocaleNotifier with ChangeNotifier {
  Locale? _locale;
  LocaleNotifier(this._locale);
  get locale => _locale;

  void setLocale(Locale newLocale) async {
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('languageCode', newLocale.languageCode);
    notifyListeners();
  }
}

// Class to hold calculator logic, accessible via Provider
class CalculatorLogic with ChangeNotifier {
  late Function(String) onKeypadPress;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? true;
  final languageCode = prefs.getString('languageCode');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) =>
                ThemeNotifier(isDarkMode ? ThemeMode.dark : ThemeMode.light)),
        ChangeNotifierProvider(
            create: (_) => LocaleNotifier(
                languageCode != null ? Locale(languageCode) : null)),
        ChangeNotifierProvider(create: (_) => CalculatorLogic()),
      ],
      child: const CalculatorApp(),
    ),
  );
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final localeNotifier = Provider.of<LocaleNotifier>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculator',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeNotifier.locale,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeNotifier.themeMode,
      home: const MainShell(),
    );
  }
}

// This is the new main screen with the Bottom Navigation Bar
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    CalculatorPage(),
    ProfilesListPage(),
    WishlistPage(),
    BudgetsPage(),
    ReportsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This Builder is needed to provide the correct context for localizations
    return Builder(builder: (context) {
      final loc = AppLocalizations.of(context)!;
      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // Allows more than 3 items
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.calculate),
              label: loc.calculatorTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people),
              label: 'Profiles', // Should be localized
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star),
              label: 'Wishlist', // Should be localized
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assessment),
              label: 'Budgets', // Should be localized
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pie_chart),
              label: 'Reports', // Should be localized
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      );
    });
  }
}
