import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

class GraficaActivosInactivosPage extends StatefulWidget {
  const GraficaActivosInactivosPage({super.key});

  @override
  _GraficaActivosInactivosPageState createState() => _GraficaActivosInactivosPageState();
}

class _GraficaActivosInactivosPageState extends State<GraficaActivosInactivosPage> {
  DateTime _selectedMonth = DateTime.now();
  List<_ChartData> _chartData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await _fetchData();
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<_ChartData>> _fetchData() async {
    final clientes = await FirebaseFirestore.instance.collection('Clientes').get();
    final warehouses = await FirebaseFirestore.instance.collection('Warehouse').get();

    Set<String> allClientes = {};
    Set<String> activeClientes = {};

    for (var doc in clientes.docs) {
      final clienteId = doc['cliente_id']?.toString().trim() ?? '';
      final fechaCreacion = doc['fecha'] as Timestamp?;

      if (clienteId.isNotEmpty && fechaCreacion != null) {
        DateTime creationDate = fechaCreacion.toDate();
        if (creationDate.year == _selectedMonth.year && creationDate.month == _selectedMonth.month) {
          allClientes.add(clienteId);
        }
      }
    }

    for (var doc in warehouses.docs) {
      final clienteId = doc['cliente_id']?.toString().trim() ?? '';
      final fechaCreacion = doc['fecha'] as Timestamp?;

      if (clienteId.isNotEmpty && fechaCreacion != null) {
        DateTime creationDate = fechaCreacion.toDate();
        if (creationDate.year == _selectedMonth.year && creationDate.month == _selectedMonth.month) {
          activeClientes.add(clienteId);
        }
      }
    }

    final activeCount = activeClientes.intersection(allClientes).length;
    final totalClientes = allClientes.length;

    if (totalClientes == 0) {
      return []; // Return empty list if no data for the selected month
    }

    double activePercentage = totalClientes > 0 ? (activeCount / totalClientes) * 100 : 0;
    double inactivePercentage = 100 - activePercentage;

    return [
      _ChartData('Clientes Activos', activePercentage, Colors.green), // Add color
      _ChartData('Clientes Inactivos', inactivePercentage, Colors.red), // Add color
    ];
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text(
          'Clientes Activos/Inactivos',
          style: TextStyle(color: Colors.white),
        ),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Center( // Center the content
                      child: Column(
                        children: [
                          SizedBox(
                            width: 300, // Make the button wider
                            child: ElevatedButton(
                              onPressed: () => _selectMonth(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade800,
                              ),
                              child: Text(
                                '${_selectedMonth.year}-${_selectedMonth.month}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(height: 20), // Add some space between the button and the chart/table
                          SizedBox( // Add SizedBox to constrain the Row
                            height: 400, // Adjust the height as needed
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center, // Center the chart and table horizontally
                              children: [
                                // Table
                                SizedBox( // Add SizedBox to constrain the table width
                                  width: 300, // Adjust the width as needed
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
                                            'Clientes Activos/Inactivos',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: _chartData.length,
                                            itemBuilder: (context, index) {
                                              final data = _chartData[index];
                                              return Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: Colors.grey.shade200,
                                                    ),
                                                  ),
                                                ),
                                                child: ListTile(
                                                  leading: Icon(Icons.circle, color: data.color),
                                                  title: Text(data.label),
                                                  trailing: Text('${data.value.toStringAsFixed(1)}%'),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 40), // Add space between the table and the pie chart
                                // Pie Chart
                                SizedBox(
                                  width: 300, // Set a fixed width
                                  height: 300, // Set a fixed height
                                  child: PieChart(
                                    PieChartData(
                                      borderData: FlBorderData(
                                        show: false,
                                      ),
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 40,
                                      sections: _chartData.map((data) {
                                        return PieChartSectionData(
                                          color: data.color,
                                          value: data.value,
                                          title: '${data.value.toStringAsFixed(1)}%',
                                          radius: 120,
                                          titleStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
      floatingActionButton: null, // Remove the floating action button
    );
  }
}

class _ChartData {
  _ChartData(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}