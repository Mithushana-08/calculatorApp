import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.system);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          home: CalculatorScreen(
            onThemeChanged: (bool isDarkMode) {
              _themeMode.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        );
      },
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const CalculatorScreen({super.key, required this.onThemeChanged});

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String output = "0";
  String expression = '';
  bool isDarkMode = false;
  List<String> history = [];

void buttonPressed(String buttonText) {
  setState(() {
    
    if (expression.isEmpty &&
        (buttonText == "+" ||
            buttonText == "-" ||
            buttonText == "÷" ||
            buttonText == "×" ||
            buttonText == "=")) {
      return;
    }

    if (buttonText == "+/-") {
      if (output.startsWith('-')) {
        output = output.substring(1);
      } else {
        output = '-$output';
      }
      expression = output;
    } 

    else if (buttonText == "AC") {
      output = "0";
      expression = '';
    } 

    else if (buttonText == "√") {
      if (expression.isEmpty) {
        expression = "√";
        output = "√";
      } else {
        expression += "√";
        output += "√";
      }
    } 

    else if (buttonText == "%") {
      if (output.isNotEmpty) {
        try {
          double currentValue = double.tryParse(output) ?? 0;
          double percentageValue = currentValue / 100;
          output = _formatResult(percentageValue);
          expression = output;
        } catch (e) {
          _showErrorDialog("Invalid percentage calculation.");
        }
      }
    } 

    else if (buttonText == "=") {
      try {
        
        String processedExpression = expression;
        while (processedExpression.contains("√")) {
          int sqrtIndex = processedExpression.indexOf("√");
          int startIndex = sqrtIndex + 1;
          int endIndex = startIndex;

          
          while (endIndex < processedExpression.length &&
              (RegExp(r'[0-9.]').hasMatch(processedExpression[endIndex]))) {
            endIndex++;
          }

          String numberStr =
              processedExpression.substring(startIndex, endIndex);
          double value = double.tryParse(numberStr) ?? 0;

          if (value < 0) {
            _showErrorDialog("Cannot calculate the square root of a negative number.");
            return;
          }

          double sqrtValue = sqrt(value);
          processedExpression = processedExpression.replaceFirst(
              "√$numberStr", sqrtValue.toString());
        }

  
        double result = _evaluateExpression(processedExpression);
        output = _formatResult(result);
        history.insert(0, "$expression = $output");
        expression = output;
      } catch (e) {
        _showErrorDialog("Cannot divide by zero!");
      }
    } 

    else {
      if (output == "0" && buttonText == "÷") {
        output = "0÷";
      } else if (output == "0÷" && buttonText == "0") {
        output = "0÷0";
      } else if (output == "0" && buttonText != ".") {
        output = buttonText;
      } else {
        output += buttonText;
      }
      expression += buttonText;
    }
  });
}

double _evaluateExpression(String expr) {
  
  expr = expr.replaceAll('×', '*').replaceAll('÷', '/');

  try {
    if (expr.trim() == "0÷0") {
      _showErrorDialog("Undefined operation: Division of zero by zero!");
      return 0; 
    }

   
    Parser parser = Parser();
    Expression parsedExpression = parser.parse(expr);

   
    double result = parsedExpression.evaluate(EvaluationType.REAL, ContextModel());

    return result;
  } catch (e) {
    _showErrorDialog("Invalid Expression!");
    return 0;
  }
}



  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String _formatResult(double result) {
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result
          .toStringAsFixed(10)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
  }

  Widget buildButton(String buttonText, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => buttonPressed(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.all(16.0),
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.5),
            shape: const CircleBorder(),
            minimumSize: const Size(75, 75),
          ),
          child: Text(
            buttonText,
            style: const TextStyle(fontSize: 24.0, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor = const Color.fromARGB(177, 36, 107, 146);
    Color greyButtonColor = isDarkMode ? Colors.grey[800]! : Colors.grey[400]!;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(42, 36, 108, 146),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () {
              widget.onThemeChanged(!isDarkMode);
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(history: history),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
              child: Text(
                output,
                style: TextStyle(
                  fontSize: 48.0,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 12.0, top: 10),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      output = output.isNotEmpty && output != "0"
                          ? output.substring(0, output.length - 1)
                          : "0";
                    });
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.backspace,
                      color: Color.fromARGB(255, 89, 85, 85),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(),
          Column(
            children: [
              Row(
                children: <Widget>[
                  buildButton("AC", buttonColor),
                  buildButton("√", buttonColor),
                  buildButton("%", buttonColor),
                  buildButton("÷", buttonColor),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  buildButton("7", greyButtonColor),
                  buildButton("8", greyButtonColor),
                  buildButton("9", greyButtonColor),
                  buildButton("×", buttonColor),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  buildButton("4", greyButtonColor),
                  buildButton("5", greyButtonColor),
                  buildButton("6", greyButtonColor),
                  buildButton("-", buttonColor),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  buildButton("1", greyButtonColor),
                  buildButton("2", greyButtonColor),
                  buildButton("3", greyButtonColor),
                  buildButton("+", buttonColor),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  buildButton("+/-", greyButtonColor),
                  buildButton("0", greyButtonColor),
                  buildButton(".", greyButtonColor),
                  buildButton("=", buttonColor),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class HistoryScreen extends StatefulWidget {
  final List<String> history;

  const HistoryScreen({super.key, required this.history});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<String> _history;

  @override
  void initState() {
    super.initState();
    _history = List.from(widget.history); 
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Expanded(
            child: _history.isEmpty
                ? const Center(
                    child: Text(
                      'No history available',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          _history[index],
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _clearHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey, 
              ),
              child: const Text('Clear All'),
            ),
          ),
        ],
      ),
    );
  }
}
