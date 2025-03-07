import 'package:flutter/material.dart';

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  _WarehousePageState createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse'),
      ),
      body: const Center(
        child: Text('Warehouse Page'),
      ),
    );
  }
}