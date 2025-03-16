import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class GraficaCasillerosMensuales extends StatefulWidget {
  const GraficaCasillerosMensuales({super.key});

  @override
  _GraficaCasillerosMensualesState createState() =>
      _GraficaCasillerosMensualesState();
}

class _GraficaCasillerosMensualesState
    extends State<GraficaCasillerosMensuales> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<_ChartData> _chartData = [];
  DateTime _selectedMonth = DateTime.now();
  int touchedIndex = -1;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(
        'es', null); // Inicializar la configuración regional
    _getChartData();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getChartData() async {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    print("Consultando clientes entre $startOfMonth y $endOfMonth");

    QuerySnapshot snapshot = await _firestore
        .collection('Clientes')
        .where('fecha',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('fecha', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    print("Documentos obtenidos: ${snapshot.docs.length}");

    final clientesPorDia = <int, int>{};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['fecha'] is Timestamp) {
        final fecha = (data['fecha'] as Timestamp).toDate();
        int dia = fecha.day;
        clientesPorDia[dia] = (clientesPorDia[dia] ?? 0) + 1;
      } else {
        print("Documento sin campo 'fecha' o tipo incorrecto: ${doc.id}");
      }
    }

    List<_ChartData> chartData = clientesPorDia.entries
        .map(
            (entry) => _ChartData(entry.key.toString(), entry.value.toDouble()))
        .toList();

    // Ordena los datos para mostrar los días de forma correcta
    chartData.sort((a, b) => int.parse(a.label).compareTo(int.parse(b.label)));
    print("Chart Data: $chartData");

    setState(() {
      _chartData = chartData;
    });
  }

  Future<QuerySnapshot> getFechaClientes() {
    return _firestore.collection('Clientes').get();
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
        _getChartData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Casilleros Mensuales'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade700, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _selectMonth(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Updated button color
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                      'Seleccionar Mes: ${DateFormat.yMMM('es').format(_selectedMonth)}'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Clientes registrados en el mes seleccionado',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Table
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
                              'Clientes por Día',
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
                                final date = DateTime(_selectedMonth.year, _selectedMonth.month, int.parse(data.label));
                                final formattedDate = DateFormat('dd MMM yyyy', 'es').format(date);
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(formattedDate),
                                    trailing: Text('${data.value.toInt()} clientes'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  // Chart
                  Expanded(
                    child: _chartData.isEmpty
                        ? const Center(child: Text('No hay clientes disponibles'))
                        : _buildChart(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = _chartData[group.x.toInt()].label;
                    return BarTooltipItem(
                      '$day\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: (rod.toY).toString(),
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        barTouchResponse == null ||
                        barTouchResponse.spot == null) {
                      touchedIndex = -1;
                      _animationController.stop();
                      return;
                    }
                    touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    _animationController.repeat();
                  });
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < _chartData.length) {
                        return Text(_chartData[index].label);
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(value.toInt().toString());
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _chartData
                  .asMap()
                  .map((index, data) => MapEntry(
                        index,
                        BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data.value,
                              color: index == touchedIndex ? Colors.yellow : Colors.blue,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1,
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .values
                  .toList(),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: RotationTransition(
              turns: _animationController,
              child: Icon(
                Icons.circle,
                size: 50,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartData {
  _ChartData(this.label, this.value);
  final String label;
  final double value;
}
