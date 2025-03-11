import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GraficaPromPage extends StatefulWidget {
  const GraficaPromPage({super.key});

  @override
  _GraficaPromPageState createState() => _GraficaPromPageState();
}

class _GraficaPromPageState extends State<GraficaPromPage> {
  DateTime _selectedMonth = DateTime.now();
  DateTimeRange? _selectedDateRange;
  List<_ChartData> _chartData = [];

  @override
  void initState() {
    super.initState();
    _getChartData();
  }

  void _getChartData() async {
    QuerySnapshot snapshot = await getPaquetes();
    double total = 0;
    double aereoCount = 0;
    double maritimoCount = 0;

    for (var doc in snapshot.docs) {
      DateTime date = (doc['Fecha'] as Timestamp).toDate();
      if (_selectedDateRange != null) {
        if (date.isAfter(_selectedDateRange!.start) && date.isBefore(_selectedDateRange!.end)) {
          total++;
          String mode = doc['Modalidad'] ?? 'Unknown';
          if (mode == 'Aereo') {
            aereoCount++;
          } else if (mode == 'Maritimo') {
            maritimoCount++;
          }
        }
      } else if (date.year == _selectedMonth.year && date.month == _selectedMonth.month) {
        total++;
        String mode = doc['Modalidad'] ?? 'Unknown';
        if (mode == 'Aereo') {
          aereoCount++;
        } else if (mode == 'Maritimo') {
          maritimoCount++;
        }
      }
    }

    if (total == 0) {
      setState(() {
        _chartData = [];
      });
      return;
    }

    List<_ChartData> chartData = [
      _ChartData('Aereo', (aereoCount / total) * 100),
      _ChartData('Maritimo', (maritimoCount / total) * 100),
    ];

    setState(() {
      _chartData = chartData;
    });
  }

  Future<QuerySnapshot> getPaquetes() {
    return FirebaseFirestore.instance.collection('Paquetes').get();
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
        _selectedDateRange = null;
        _getChartData();
      });
    }
  }

  void _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange && picked.duration.inDays <= 31) {
      setState(() {
        _selectedDateRange = picked;
        _selectedMonth = DateTime.now();
        _getChartData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text(
          'Promedio de Clientes',
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
                ElevatedButton(
                  onPressed: () => _selectDateRange(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                  ),
                  child: const Text(
                    'Seleccionar Rango de Fechas',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SfCircularChart(
                title: ChartTitle(text: 'Promedio de Clientes por Modalidad'),
                legend: Legend(isVisible: true),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CircularSeries<_ChartData, String>>[
                  PieSeries<_ChartData, String>(
                    dataSource: _chartData,
                    xValueMapper: (_ChartData data, _) => data.mode,
                    yValueMapper: (_ChartData data, _) => data.average,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    dataLabelMapper: (_ChartData data, _) => '${data.average.toStringAsFixed(1)}%',
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
  _ChartData(this.mode, this.average);
  final String mode;
  final double average;
}