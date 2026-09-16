import 'package:flutter/material.dart';

class SikarirApp extends StatelessWidget {
  const SikarirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIKARIR',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('SIKARIR'),
        ),
      ),
    );
  }
}