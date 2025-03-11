import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Asegúrate de tener esta dependencia en tu pubspec.yaml
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class PromPesoPage extends StatefulWidget {
  const PromPesoPage({super.key});

  @override
  _PromPesoPageState createState() => _PromPesoPageState();
}

class _PromPesoPageState extends State<PromPesoPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, 3); // Iniciar con marzo
  double avgPeso = 0.0;
  double avgWarehouse = 0.0;
  double avgPaquetes = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    avgPeso = await getPromedioCargas();
    avgWarehouse = await getPromedioWarehouse();
    avgPaquetes = await getPromedioPaquetes();
    setState(() {});
  }

  Future<double> getPromedioPaquetes() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Paquetes')
        .where('Fecha', isGreaterThanOrEqualTo: _selectedMonth, isLessThan: DateTime(_selectedMonth.year, _selectedMonth.month + 1))
        .get();
    double totalPeso = 0;
    for (var doc in querySnapshot.docs) {
      totalPeso += doc['Peso'];
    }
    return totalPeso / querySnapshot.size;
  }

  Future<double> getPromedioWarehouse() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Warehouse')
        .where('fecha', isGreaterThanOrEqualTo: _selectedMonth, isLessThan: DateTime(_selectedMonth.year, _selectedMonth.month + 1))
        .get();
    double totalPeso = 0;
    for (var doc in querySnapshot.docs) {
      totalPeso += doc['peso_total'];
    }
    return totalPeso / querySnapshot.size;
  }

  Future<double> getPromedioCargas() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Carga')
        .where('fecha', isGreaterThanOrEqualTo: _selectedMonth, isLessThan: DateTime(_selectedMonth.year, _selectedMonth.month + 1))
        .get();
    double totalPeso = 0;
    for (var doc in querySnapshot.docs) {
      totalPeso += doc['peso'];
    }
    return totalPeso / querySnapshot.size;
  }

  void _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
        _fetchData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promedios del Mes'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.orange.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _selectMonth(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                  ),
                  child: Text(
                    'Seleccionar Mes: ${DateFormat.yMMM().format(_selectedMonth)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildTable('Promedio de Peso de las Cargas', avgPeso),
                  _buildTable('Promedio de Peso de los Warehouse', avgWarehouse),
                  _buildTable('Promedio de Peso de los Paquetes', avgPaquetes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(String title, double average) {
    return Card(
      margin: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          ListTile(
            title: Text(title),
          ),
          DataTable(
            columns: const [
              DataColumn(label: Text('Mes')),
              DataColumn(label: Text('Promedio')),
            ],
            rows: [
              DataRow(cells: [
                DataCell(Text(DateFormat.yMMM().format(_selectedMonth))),
                DataCell(Text(average.toStringAsFixed(2))),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}