import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'colors.dart';
import 'main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// --- WIDGETS ---

Widget buildStandardCalculator(BuildContext context, String equation, String result) {
  return Column(
    children: [
      Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Text(
          equation,
          style: TextStyle(
            fontSize: 38.0,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ),
      Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.fromLTRB(10, 30, 10, 0),
        child: Text(
          result,
          style: TextStyle(
            fontSize: 48.0,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const Divider(),
      Expanded(child: buildKeypad(context)),
    ],
  );
}

Widget buildCurrencyCalculator(
  BuildContext context,
  AppLocalizations loc,
  TextEditingController a1, TextEditingController a2, TextEditingController a3,
  FocusNode f1, FocusNode f2, FocusNode f3,
  String op1, String op2,
  String field1Hint, String field2Hint, String field3Hint,
  double? currencyResult,
  String resultNote
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final operatorColor = isDark ? Colors.white : Colors.black87;

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            buildCurrencyField(context, a1, field1Hint, f1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(op1, style: TextStyle(fontSize: 24, color: operatorColor)),
            ),
            buildCurrencyField(context, a2, field2Hint, f2),
            if (a3.text.isNotEmpty || field3Hint != '0')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(op2, style: TextStyle(fontSize: 24, color: operatorColor)),
              ),
            if (a3.text.isNotEmpty || field3Hint != '0')
              buildCurrencyField(context, a3, field3Hint, f3),
          ],
        ),
      ),
      if (currencyResult != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? darkResultBoxColor : lightResultBoxColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            currencyResult.isNaN
                ? loc.error
                : '$resultNote: ${NumberFormat('#,##0.####').format(currencyResult)}',
            style: TextStyle(
              color: isDark ? darkNumTextColor : lightNumTextColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      const Spacer(),
      buildKeypad(context),
    ],
  );
}

Widget buildCurrencyField(BuildContext context, TextEditingController c, String hint, FocusNode f) {
  return Expanded(
    child: TextField(
      controller: c,
      focusNode: f,
      style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
      keyboardType: TextInputType.none,
      decoration: InputDecoration(labelText: hint, isDense: true),
    ),
  );
}

Widget buildKeypad(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Button Colors
  final numColor = isDark ? darkNumButtonColor : lightNumButtonColor;
  final opColor = isDark ? darkOpButtonColor : lightOpButtonColor;
  final eqColor = isDark ? darkEqButtonColor : lightEqButtonColor;

  // Text Colors
  final numTextColor = isDark ? darkNumTextColor : lightNumTextColor;
  final opTextColor = isDark ? darkOpTextColor : lightOpTextColor;
  final cTextColor = isDark ? Colors.redAccent : Colors.red;

  Widget buildButton(String buttonText, Color buttonColor, {Color textColor = Colors.white}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          onPressed: () {
            Provider.of<CalculatorLogic>(context, listen: false).onKeypadPress(buttonText);
          },
          style: ElevatedButton.styleFrom(
            elevation: isDark ? 4 : 1,
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
            padding: const EdgeInsets.all(22.0),
          ),
          child: Text(
            buttonText,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ),
    );
  }

  return Container(
    color: isDark ? darkAppBarBg : const Color(0xFFECEFF1),
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: [
        Row(children: [
          buildButton("C", opColor, textColor: cTextColor),
          buildButton("7", numColor, textColor: numTextColor),
          buildButton("8", numColor, textColor: numTextColor),
          buildButton("9", numColor, textColor: numTextColor),
        ]),
        Row(children: [
          buildButton("÷", opColor, textColor: opTextColor),
          buildButton("4", numColor, textColor: numTextColor),
          buildButton("5", numColor, textColor: numTextColor),
          buildButton("6", numColor, textColor: numTextColor),
        ]),
        Row(children: [
          buildButton("×", opColor, textColor: opTextColor),
          buildButton("1", numColor, textColor: numTextColor),
          buildButton("2", numColor, textColor: numTextColor),
          buildButton("3", numColor, textColor: numTextColor),
        ]),
        Row(children: [
          buildButton("-", opColor, textColor: opTextColor),
          buildButton("0", numColor, textColor: numTextColor),
          buildButton(".", numColor, textColor: numTextColor),
          buildButton("⌫", opColor, textColor: opTextColor),
        ]),
        Row(children: [
          buildButton("+", opColor, textColor: opTextColor),
          Expanded(flex: 3, child: buildButton("=", eqColor)),
        ]),
      ],
    ),
  );
}