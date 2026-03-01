import 'package:flutter/material.dart';
import 'package:crm2/ui_v1/ui_v1.dart';

/// Dev switch: true = UiV1PlaygroundPage (ui_v1 theme), false = legacy MyHomePage.
const bool kUseUiV1 = true;

void main() {
  runApp(kUseUiV1 ? const _UiV1App() : const MyApp());
}

/// Root when kUseUiV1: applies ui_v1 light/dark theme and theme toggle.
class _UiV1App extends StatefulWidget {
  const _UiV1App();

  @override
  State<_UiV1App> createState() => _UiV1AppState();
}

class _UiV1AppState extends State<_UiV1App> {
  ThemeMode _themeMode = ThemeMode.light;
  final OrdersListState _ordersListState = OrdersListState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM2',
      theme: getTheme(Brightness.light, UiV1Density.dense),
      darkTheme: getTheme(Brightness.dark, UiV1Density.dense),
      themeMode: _themeMode,
      home: UiV1PlaygroundPage(
        listState: _ordersListState,
        onThemeToggle: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.light
                ? ThemeMode.dark
                : ThemeMode.light;
          });
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'CRM2 Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
