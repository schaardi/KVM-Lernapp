import 'package:flutter/material.dart';
import '../constants.dart';

/// Einfacher Taschenrechner mit sicherer Ausdrucksauswertung (Shunting-Yard).
class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key});
  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _expr = '';
  String _res = '0';

  void _press(String k) {
    setState(() {
      if (k == 'C') {
        _expr = '';
        _res = '0';
      } else if (k == '⌫') {
        if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
      } else if (k == '=') {
        final v = _eval(_expr);
        _res = v == null ? 'Fehler' : _fmt(v);
      } else {
        _expr += k;
      }
    });
  }

  String _fmt(double x) {
    if (x == x.roundToDouble()) return x.toInt().toString();
    return x.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  double? _eval(String s) {
    try {
      final tokens = _tokenize(s);
      final rpn = _toRpn(tokens);
      return _evalRpn(rpn);
    } catch (_) {
      return null;
    }
  }

  List<String> _tokenize(String s) {
    final out = <String>[];
    var i = 0;
    while (i < s.length) {
      final c = s[i];
      if (c == ' ') {
        i++;
        continue;
      }
      if (RegExp(r'[0-9.]').hasMatch(c)) {
        var j = i;
        while (j < s.length && RegExp(r'[0-9.]').hasMatch(s[j])) {
          j++;
        }
        out.add(s.substring(i, j));
        i = j;
        continue;
      }
      if ('+-*/()'.contains(c)) {
        out.add(c);
        i++;
        continue;
      }
      throw Exception('bad');
    }
    return out;
  }

  List<String> _toRpn(List<String> tokens) {
    final out = <String>[];
    final ops = <String>[];
    const prec = {'+': 1, '-': 1, '*': 2, '/': 2};
    for (final t in tokens) {
      if (double.tryParse(t) != null) {
        out.add(t);
      } else if (prec.containsKey(t)) {
        while (ops.isNotEmpty &&
            prec.containsKey(ops.last) &&
            prec[ops.last]! >= prec[t]!) {
          out.add(ops.removeLast());
        }
        ops.add(t);
      } else if (t == '(') {
        ops.add(t);
      } else if (t == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          out.add(ops.removeLast());
        }
        if (ops.isNotEmpty) ops.removeLast();
      }
    }
    while (ops.isNotEmpty) {
      out.add(ops.removeLast());
    }
    return out;
  }

  double _evalRpn(List<String> rpn) {
    final st = <double>[];
    for (final t in rpn) {
      final n = double.tryParse(t);
      if (n != null) {
        st.add(n);
      } else {
        final b = st.removeLast();
        final a = st.removeLast();
        st.add(switch (t) {
          '+' => a + b,
          '-' => a - b,
          '*' => a * b,
          '/' => a / b,
          _ => throw Exception('op'),
        });
      }
    }
    return st.single;
  }

  @override
  Widget build(BuildContext context) {
    const keys = [
      '7', '8', '9', '/',
      '4', '5', '6', '*',
      '1', '2', '3', '-',
      '0', '.', '=', '+',
      '(', ')', '⌫', 'C',
    ];
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFF0F1E23),
                borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_expr,
                    style: const TextStyle(color: Color(0xFF8FB6BD), fontSize: 14)),
                Text(_res,
                    style: const TextStyle(
                        color: Color(0xFFEAFAFF),
                        fontSize: 30,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              for (final k in keys)
                ElevatedButton(
                  onPressed: () => _press(k),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: k == '=' ? kPetrol : Colors.white,
                    foregroundColor: k == '=' ? Colors.white : kInk,
                    elevation: 0,
                    side: const BorderSide(color: kLine),
                  ),
                  child: Text(k, style: const TextStyle(fontSize: 18)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
