import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

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
      _ChartData('Activos', activePercentage),
      _ChartData('Inactivos', inactivePercentage),
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
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => _selectMonth(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                        ),
                        child: Text(
                          'Mes seleccionado: ${_selectedMonth.year}-${_selectedMonth.month}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: _chartData.isEmpty // Check if _chartData is empty
                            ? const Center(child: Text('No hay datos que mostrar para este mes.', style: TextStyle(color: Colors.white))) // Display message if no data
                            : SfCircularChart(
                                title: ChartTitle(text: 'Clientes Activos/Inactivos'),
                                legend: Legend(isVisible: true),
                                series: <CircularSeries<_ChartData, String>>[
                                  PieSeries<_ChartData, String>(
                                    dataSource: _chartData,
                                    xValueMapper: (_ChartData data, _) => data.label,
                                    yValueMapper: (_ChartData data, _) => data.value,
                                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                                    dataLabelMapper: (datum, index) =>
                                        '${datum.label}: ${datum.value.toStringAsFixed(1)}%',
                                  )
                                ],
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.label, this.value);

  final String label;
  final double value;
}