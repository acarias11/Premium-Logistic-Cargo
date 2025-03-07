//importar material
import 'package:flutter/material.dart';

//creacion de la clase
class CargasPage extends StatefulWidget {
  const CargasPage({super.key});

  @override
  _CargasPageState createState() => _CargasPageState();
}

class _CargasPageState extends State<CargasPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargas'),
      ),
      body: const Center(
        child: Text('Cargas Page'),
      ),
    );
  }
}