import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'pages/home_page.dart';

void main() {
  // Enable comprehensive logging for debugging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      // ignore: avoid_print
      print('  Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print('  Stack trace: ${record.stackTrace}');
    }
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ID OCR Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
