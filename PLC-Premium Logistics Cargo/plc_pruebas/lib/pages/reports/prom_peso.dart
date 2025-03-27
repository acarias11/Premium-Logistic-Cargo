import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:fl_chart/fl_chart.dart';

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
    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        totalPeso += (doc['Peso'] as num).toDouble();
      }
      return totalPeso / querySnapshot.size;
    } else {
      return 0.0;
    }
  }

  Future<double> getPromedioWarehouse() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Warehouse')
        .where('fecha', isGreaterThanOrEqualTo: _selectedMonth, isLessThan: DateTime(_selectedMonth.year, _selectedMonth.month + 1))
        .get();
    double totalPeso = 0;
    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        totalPeso += (doc['peso_total'] as num).toDouble();
      }
      return totalPeso / querySnapshot.size;
    } else {
      return 0.0;
    }
  }

  Future<double> getPromedioCargas() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Carga')
        .where('fecha', isGreaterThanOrEqualTo: _selectedMonth, isLessThan: DateTime(_selectedMonth.year, _selectedMonth.month + 1))
        .get();
    double totalPeso = 0;
    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        totalPeso += (doc['peso'] as num).toDouble();
      }
      return totalPeso / querySnapshot.size;
    } else {
      return 0.0;
    }
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
        backgroundColor: const Color.fromARGB(255, 10, 50, 110),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 10, 50, 110), const Color.fromARGB(255, 10, 50, 110)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Promedios de Peso por Categoría',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _selectMonth(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                          'Seleccionar Mes: ${DateFormat.yMMM().format(_selectedMonth)}'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Main Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Section
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen de Promedios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildTable('Promedio de Peso de las Cargas', avgPeso),
                            _buildTable('Promedio de Peso de los Warehouse', avgWarehouse),
                            _buildTable('Promedio de Peso de los Paquetes', avgPaquetes),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Chart Section
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Distribución de Promedios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: _buildChart(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(String title, double average) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Add padding
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: Text(
                  DateFormat.yMMM().format(_selectedMonth),
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: Text(
                  '${average.toStringAsFixed(2)} kg',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return SizedBox(
      width: 300, // Set a fixed width
      height: 300, // Set a fixed height
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: avgPeso,
              color: Colors.blueAccent,
              title: 'Cargas',
              radius: 120,
            ),
            PieChartSectionData(
              value: avgWarehouse,
              color: Colors.greenAccent,
              title: 'Warehouse',
              radius: 120,
            ),
            PieChartSectionData(
              value: avgPaquetes,
              color: Colors.orangeAccent,
              title: 'Paquetes',
              radius: 120,
            ),
          ],
          borderData: FlBorderData(
            show: false,
          ),
          sectionsSpace: 0,
          centerSpaceRadius: 50,
        ),
      ),
    );
  }

}