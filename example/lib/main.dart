import 'package:flutter/material.dart';
import 'package:resource_storage_hive/resource_storage_hive.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: ElevatedButton(
          child: const Text('Open Demo Page'),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const DemoPage()));
          },
        ),
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  Value _value = Value(0);
  late HiveResourceStorage<String, Value> _storage;

  @override
  void initState() {
    super.initState();
    _storage = HiveResourceStorage<String, Value>(
      storageName: 'value_storage',
      decode: Value.fromJson,
    );
    _refreshCounter();
  }

  void _refreshCounter() async {
    final cache = await _storage.getOrNull('counter');
    setState(() {
      _value = cache?.value ?? Value(0);
    });
  }

  void _incrementCounter() async {
    await _storage.put('counter', _value + 1);
    _refreshCounter();
  }

  void _resetCounter() async {
    await _storage.remove('counter');
    _refreshCounter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Demo page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '${_value.counter}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetCounter,
              child: const Text('Reset'),
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

class Value {
  Value(this.counter);

  final int counter;

  Value operator +(int a) => Value(counter + a);

  @override
  String toString() => 'Value($counter)';

  Map<String, dynamic> toJson() {
    return {'counter': counter};
  }

  factory Value.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return Value(map['counter'] as int);
  }
}
