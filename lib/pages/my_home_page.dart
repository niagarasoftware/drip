import 'package:flutter/material.dart';
import '../flavors.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(F.name),
      ),
      body: Center(
        child: Text(
          'Hello ${F.name}',
        ),
      ),
    );
  }
}
