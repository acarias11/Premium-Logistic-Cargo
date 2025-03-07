import 'package:flutter/material.dart';

class QuejasPage extends StatefulWidget {
  const QuejasPage({super.key});

  @override
  _QuejasPageState createState() => _QuejasPageState();
}

class _QuejasPageState extends State<QuejasPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quejas'),
      ),
      body: const Center(
        child: Text('Quejas Page'),
      ),
    );
  }
}