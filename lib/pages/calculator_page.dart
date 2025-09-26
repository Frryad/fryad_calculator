import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../settings.dart';
import '../num_calculator.dart';
import 'profiles_list_page.dart';

// The enum now lives in the file where it is primarily used.
enum CalculatorMode { standard, currency, programmer }

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  // --- STATE VARIABLES ---
  CalculatorMode _calculatorMode = CalculatorMode.standard;
  String equation = "0", result = "0";
  final List<Map<String, dynamic>> history = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Currency State
  final _a1 = TextEditingController(), _a2 = TextEditingController(), _a3 = TextEditingController();
  final _f1 = FocusNode(), _f2 = FocusNode(), _f3 = FocusNode();
  String _op1 = '+', _op2 = '+';
  double? _currencyResult;
  String _field1Hint = '', _field2Hint = '', _field3Hint = '';
  String _resultNoteKey = '';

  // Programmer Mode State
  BigInt _programmerValue = BigInt.zero;
  String _programmerInput = "0";
  String? _pendingOperation;
  BigInt? _pendingValue;

  @override
  void initState() {
    super.initState();
    Provider.of<CalculatorLogic>(context, listen: false).onKeypadPress = _onKeypadPress;
    _loadData();
    _a1.addListener(_currencyCalc);
    _a2.addListener(_currencyCalc);
    _a3.addListener(_currencyCalc);
  }

  @override
  void dispose() {
    _a1.dispose(); _a2.dispose(); _a3.dispose();
    _f1.dispose(); _f2.dispose(); _f3.dispose();
    super.dispose();
  }

  // --- DATA PERSISTENCE ---
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('calculatorMode', _calculatorMode.index);
    prefs.setString('a1', _a1.text);
    prefs.setString('a2', _a2.text);
    prefs.setString('a3', _a3.text);
    prefs.setString('resultNoteKey', _resultNoteKey);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _calculatorMode = CalculatorMode.values[prefs.getInt('calculatorMode') ?? 0];
      _a1.text = prefs.getString('a1') ?? '';
      _a2.text = prefs.getString('a2') ?? '';
      _a3.text = prefs.getString('a3') ?? '';
      _resultNoteKey = prefs.getString('resultNoteKey') ?? '';
      if (_calculatorMode == CalculatorMode.currency && _resultNoteKey.isNotEmpty) {
        _restorePresetByNoteKey(_resultNoteKey);
      }
    });
  }

  void _restorePresetByNoteKey(String key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context)!;
      Map<String, Map<String, dynamic>> presets = {
        "dinarPrice": {"op1": "×", "op2": "×", "h1": loc.poundRate, "h2": loc.poundAmount, "h3": loc.dollarRate},
        "poundPrice": {"op1": "÷", "op2": "÷", "h1": loc.dinarAmount, "h2": loc.poundRate, "h3": loc.dollarRate},
      };
      if (presets.containsKey(key)) {
        var p = presets[key]!;
        _field1Hint = p["h1"];_field2Hint = p["h2"];_field3Hint = p["h3"];
        _op1 = p["op1"];_op2 = p["op2"];
      }
      _currencyCalc();
    });
  }

  // --- LOGIC ROUTER ---
  void _onKeypadPress(String buttonText) {
    if (!mounted) return;
    switch (_calculatorMode) {
      case CalculatorMode.standard:
        _standardButtonPress(buttonText);
        break;
      case CalculatorMode.currency:
        if (buttonText == '=') _handleCurrencyEquals();
        else _currencyKeypadPress(buttonText);
        break;
      case CalculatorMode.programmer:
        _programmerButtonPress(buttonText);
        break;
    }
  }

  // --- Standard Calculator Logic ---
  void _standardButtonPress(String buttonText) {
    setState(() {
      if (buttonText == "C") { equation = "0"; result = "0"; }
      else if (buttonText == "⌫") { equation = equation.length > 1 ? equation.substring(0, equation.length - 1) : "0"; }
      else if (buttonText == "=") {
        try {
          String expression = equation.replaceAll('×', '*').replaceAll('÷', '/');
          Parser p = Parser();
          Expression exp = p.parse(expression);
          result = NumberFormat('#,##0.####').format(exp.evaluate(EvaluationType.REAL, ContextModel()));
          history.insert(0, {'equation': equation, 'result': result, 't': DateTime.now()});
        } catch (e) { result = AppLocalizations.of(context)!.error; }
      } else {
        if (equation == "0") equation = buttonText;
        else equation += buttonText;
      }
    });
  }

  // --- Currency Calculator Logic ---
  void _currencyKeypadPress(String value) {
    if (value == 'C') {
      _a1.clear(); _a2.clear(); _a3.clear();
      return;
    }
    TextEditingController? controller;
    if (_f1.hasFocus) controller = _a1;
    else if (_f2.hasFocus) controller = _a2;
    else if (_f3.hasFocus) controller = _a3;
    else {
      // Defer the focus request to prevent the error on web
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_f1);
        }
      });
      controller = _a1;
    }
    
    if (value == '⌫') {
      if (controller.text.isNotEmpty) {
        controller.text = controller.text.substring(0, controller.text.length - 1);
      }
    } else {
      controller.text += value;
    }
    _currencyCalc();
  }
  void _handleCurrencyEquals() {
    _currencyCalc();
    if (_currencyResult != null && !_currencyResult!.isNaN) {
      setState(() {
        final entry = '${_a1.text} $_op1 ${_a2.text} ' + (_a3.text.isNotEmpty ? '$_op2 ${_a3.text}' : '');
        history.insert(0, {
          'equation': entry, 'result': NumberFormat('#,##0.####').format(_currencyResult!),
          'note': _getTranslatedNote(_resultNoteKey), 't': DateTime.now()
        });
      });
    }
  }
  void _currencyCalc() {
    final x = double.tryParse(_a1.text) ?? 0;
    final y = double.tryParse(_a2.text) ?? 0;
    final z = double.tryParse(_a3.text.isEmpty ? '0' : _a3.text) ?? 0;
    double apply(double v1, double v2, String op) {
      switch (op) { case '+': return v1 + v2; case '-': return v1 - v2; case '×': return v1 * v2; case '÷': return v2 == 0 ? double.nan : v1 / v2; default: return v1; }
    }
    final r1 = apply(x, y, _op1);
    final r = _a3.text.isEmpty ? r1 : apply(r1, z, _op2);
    if(mounted) setState(() => _currencyResult = r.isFinite ? r : double.nan);
    _saveData();
  }
  String _getTranslatedNote(String key) {
    if (!mounted) return "";
    final loc = AppLocalizations.of(context)!;
    switch (key) {
      case "dinarPrice": return loc.dinarPrice; case "poundPrice": return loc.poundPrice;
      case "tomanPrice": return loc.tomanPrice; case "dollarPrice": return loc.dollarPrice;
      default: return "";
    }
  }

  // --- Programmer Calculator Logic ---
  void _programmerButtonPress(String buttonText) {
    const hexChars = "ABCDEF";
    const ops = {"AND": "&", "OR": "|", "XOR": "^"};
    setState(() {
      if (buttonText == "C") {
        _programmerInput = "0"; _programmerValue = BigInt.zero;
        _pendingOperation = null; _pendingValue = null;
      } else if (hexChars.contains(buttonText) || (int.tryParse(buttonText) != null)) {
        if (_programmerInput == "0") _programmerInput = buttonText;
        else _programmerInput += buttonText;
        _programmerValue = BigInt.tryParse(_programmerInput, radix: 16) ?? BigInt.zero;
      } else if (ops.containsKey(buttonText)) {
        _performProgrammerOperation();
        _pendingOperation = ops[buttonText];
        _pendingValue = _programmerValue;
        _programmerInput = "0";
      } else if (buttonText == "=") {
        _performProgrammerOperation();
        _pendingOperation = null; _pendingValue = null;
      }
    });
  }
  void _performProgrammerOperation() {
    if (_pendingOperation != null && _pendingValue != null) {
      switch (_pendingOperation) {
        case "&": _programmerValue = _pendingValue! & _programmerValue; break;
        case "|": _programmerValue = _pendingValue! | _programmerValue; break;
        case "^": _programmerValue = _pendingValue! ^ _programmerValue; break;
      }
      _programmerInput = _programmerValue.toRadixString(16).toUpperCase();
    }
  }

  // --- DRAWER ACTIONS ---
  void _changeMode(CalculatorMode mode) {
    if (_calculatorMode == mode) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      return;
    }
    setState(() {
      _calculatorMode = mode;
      // Reset other modes' states
      equation = "0"; result = "0";
      _programmerInput = "0"; _programmerValue = BigInt.zero;
    });
    if (Navigator.canPop(context)) Navigator.pop(context);
    _saveData();
  }
  void _setPreset({
    required String op1, required String op2, required String hint1,
    required String hint2, required String hint3, required String noteKey,
  }) {
    setState(() {
      _calculatorMode = CalculatorMode.currency;
      _op1 = op1; _op2 = op2; _field1Hint = hint1; _field2Hint = hint2;
      _field3Hint = hint3; _resultNoteKey = noteKey; _currencyResult = null;
      _a1.clear(); _a2.clear(); _a3.clear();
    });
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => FocusScope.of(context).requestFocus(_f1));
    _saveData();
  }

  // --- UI WIDGETS ---
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Builder(
          builder: (context) {
            final loc = AppLocalizations.of(context)!;
            final isLandscape = orientation == Orientation.landscape;

            return Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                title: Text(_getAppBarTitle(loc)),
                leading: isLandscape ? null : IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                automaticallyImplyLeading: !isLandscape,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.people), // Changed from person
                    tooltip: 'Profiles',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilesListPage()));
                    },
                  ),
                  if (!isLandscape)
                    IconButton(icon: const Icon(Icons.history), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
                  ),
                ],
              ),
              drawer: isLandscape ? null : _buildDrawer(loc),
              endDrawer: isLandscape ? null : _buildHistoryDrawer(loc),
              body: isLandscape ? _buildLandscapeLayout(loc) : _buildPortraitLayout(loc),
            );
          },
        );
      },
    );
  }

  String _getAppBarTitle(AppLocalizations loc) {
    switch (_calculatorMode) {
      case CalculatorMode.standard: return loc.calculatorTitle;
      case CalculatorMode.currency: return _getTranslatedNote(_resultNoteKey);
      case CalculatorMode.programmer: return "Programmer"; // Should be localized
    }
  }

  Widget _buildPortraitLayout(AppLocalizations loc) {
    switch (_calculatorMode) {
      case CalculatorMode.standard:
        return buildStandardCalculator(context, equation, result);
      case CalculatorMode.currency:
        return buildCurrencyCalculator(context, loc, _a1, _a2, _a3, _f1, _f2, _f3,
            _op1, _op2, _field1Hint, _field2Hint, _field3Hint,
            _currencyResult, _getTranslatedNote(_resultNoteKey));
      case CalculatorMode.programmer:
        return _buildProgrammerCalculator();
    }
  }

  Widget _buildLandscapeLayout(AppLocalizations loc) {
    return Row(
      children: [
        SizedBox(width: 250, child: _buildDrawer(loc, isPermanent: true)),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(flex: 3, child: _buildPortraitLayout(loc)),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(flex: 2, child: _buildHistoryList(loc, isPermanent: true)),
      ],
    );
  }

  Widget _buildDrawer(AppLocalizations loc, {bool isPermanent = false}) {
    return Drawer(
      elevation: isPermanent ? 0 : 16,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (!isPermanent)
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF292D36)),
              child: Text(loc.menuHeader, style: const TextStyle(color: Colors.white, fontSize: 24)),
            ),
          ListTile(leading: const Icon(Icons.calculate), title: Text(loc.standardCalculator), onTap: () => _changeMode(CalculatorMode.standard)),
          ListTile(leading: const Icon(Icons.code), title: const Text("Programmer"), onTap: () => _changeMode(CalculatorMode.programmer)),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(loc.currencyConversions, style: Theme.of(context).textTheme.bodySmall),
          ),
          ListTile(title: Text(loc.poundToDinar), onTap: () => _setPreset(op1: '×', op2: '×', hint1: loc.poundRate, hint2: loc.poundAmount, hint3: loc.dollarRate, noteKey: 'dinarPrice')),
          ListTile(title: Text(loc.tomanToDinar), onTap: () => _setPreset(op1: '÷', op2: '×', hint1: loc.tomanAmount, hint2: loc.tomanRate, hint3: loc.dollarRate, noteKey: 'dinarPrice')),
          ListTile(title: Text(loc.dollarToDinar), onTap: () => _setPreset(op1: '×', op2: '+', hint1: loc.dollarAmount, hint2: loc.dollarRate, hint3: '0', noteKey: 'dinarPrice')),
          const Divider(),
          ListTile(title: Text(loc.dinarToPound), onTap: () => _setPreset(op1: '÷', op2: '÷', hint1: loc.dinarAmount, hint2: loc.poundRate, hint3: loc.dollarRate, noteKey: 'poundPrice')),
          ListTile(title: Text(loc.dinarToToman), onTap: () => _setPreset(op1: '÷', op2: '×', hint1: loc.dinarAmount, hint2: loc.dollarRate, hint3: loc.tomanRate, noteKey: 'tomanPrice')),
          ListTile(title: Text(loc.dinarToDollar), onTap: () => _setPreset(op1: '÷', op2: '+', hint1: loc.dinarAmount, hint2: loc.dollarRate, hint3: '0', noteKey: 'dollarPrice')),
        ],
      ),
    );
  }

  Drawer _buildHistoryDrawer(AppLocalizations loc) => Drawer(child: _buildHistoryList(loc));

  Widget _buildHistoryList(AppLocalizations loc, {bool isPermanent = false}) {
    return Column(
      children: [
        if (!isPermanent)
          AppBar(
            title: const Text("History"), automaticallyImplyLeading: false,
            actions: [IconButton(onPressed: () => setState(() => history.clear()), icon: const Icon(Icons.delete_forever))],
          )
        else
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("History", style: Theme.of(context).textTheme.titleLarge),
                IconButton(onPressed: () => setState(() => history.clear()), icon: const Icon(Icons.delete_forever)),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final shareText = '${item['equation']} = ${item['result']} ${item['note'] ?? ''}';
              return ListTile(
                title: Text('${item['equation']} = ${item['result']}'),
                subtitle: Text(item['note'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  tooltip: 'Share calculation',
                  onPressed: () { Share.share(shareText); },
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // --- Programmer Mode UI ---
  Widget _buildProgrammerCalculator() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildProgrammerDisplayRow("HEX", _programmerValue.toRadixString(16).toUpperCase()),
              _buildProgrammerDisplayRow("DEC", _programmerValue.toRadixString(10)),
              _buildProgrammerDisplayRow("BIN", _programmerValue.toRadixString(2)),
            ],
          ),
        ),
        const Divider(),
        Expanded(child: _buildProgrammerKeypad()),
      ],
    );
  }
  Widget _buildProgrammerDisplayRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontSize: 18, color: Colors.grey)),
          Expanded(child: SelectableText(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
  Widget _buildProgrammerKeypad() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final opColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    Widget buildButton(String text, {bool enabled = true, Color? color}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: enabled ? () => _onKeypadPress(text) : null,
            child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(children: [buildButton("A"), buildButton("B"), buildButton("C"), buildButton("D"), buildButton("E"), buildButton("F")]),
          Row(children: [buildButton("AND", color: opColor), buildButton("7"), buildButton("8"), buildButton("9")]),
          Row(children: [buildButton("OR", color: opColor), buildButton("4"), buildButton("5"), buildButton("6")]),
          Row(children: [buildButton("XOR", color: opColor), buildButton("1"), buildButton("2"), buildButton("3")]),
          Row(children: [buildButton("C"), Expanded(child: buildButton("0", enabled: _programmerInput != "0")), buildButton("=")]),
        ],
      ),
    );
  }
}