import 'package:flutter/material.dart';
import 'colors.dart';

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'NotoSansArabic',
  scaffoldBackgroundColor: darkScaffoldBg,
  primarySwatch: Colors.blueGrey,
  appBarTheme: const AppBarTheme(
    backgroundColor: darkAppBarBg,
    elevation: 0,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    labelStyle: TextStyle(color: Colors.white70),
    hintStyle: TextStyle(color: Colors.white38),
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Colors.white),
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: darkDrawerBg),
);

final lightTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'NotoSansArabic',
  scaffoldBackgroundColor: lightScaffoldBg,
  primarySwatch: Colors.blueGrey,
  appBarTheme: const AppBarTheme(
      backgroundColor: lightAppBarBg,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w500)),
  inputDecorationTheme: const InputDecorationTheme(
    labelStyle: TextStyle(color: Colors.black54),
    hintStyle: TextStyle(color: Colors.black38),
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black38)),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: lightNumTextColor),
    titleMedium: TextStyle(color: lightNumTextColor),
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: lightDrawerBg),
);