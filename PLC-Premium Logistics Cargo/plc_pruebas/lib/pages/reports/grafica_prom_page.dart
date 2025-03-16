import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficaPromPage extends StatefulWidget {
  const GraficaPromPage({super.key});

  @override
  _GraficaPromPageState createState() => _GraficaPromPageState();
}

class _GraficaPromPageState extends State<GraficaPromPage> {
  DateTime _selectedMonth = DateTime.now();
  DateTimeRange? _selectedDateRange;
  List<_ChartData> _chartData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getChartData();
  }

  void _getChartData() async {
    setState(() {
      _isLoading = true;
    });
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
        _isLoading = false;
      });
      return;
    }

    List<_ChartData> chartData = [
      _ChartData('Aereo', (aereoCount / total) * 100, Colors.blue),
      _ChartData('Maritimo', (maritimoCount / total) * 100, Colors.green),
    ];

    setState(() {
      _chartData = chartData;
      _isLoading = false;
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
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
                      SizedBox(height: 20),
                      SizedBox(
                        height: 400,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 300,
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
                                        'Promedio de Clientes por Modalidad',
                                        style: TextStyle(
                                          fontSize: 18,
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
                                              title: Text(data.mode),
                                              trailing: Text('${data.average.toStringAsFixed(1)}%'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 400,
                              height: 400,
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
                                      value: data.average,
                                      title: '${data.average.toStringAsFixed(1)}%',
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
      )
    );
  }
}

class _ChartData {
  _ChartData(this.mode, this.average, this.color);
  final String mode;
  final double average;
  final Color color;
}