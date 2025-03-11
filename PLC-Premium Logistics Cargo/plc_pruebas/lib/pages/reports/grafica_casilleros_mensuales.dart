import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_charts/flutter_charts.dart';
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
    extends State<GraficaCasillerosMensuales> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<_ChartData> _chartData = [];
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(
        'es', null); // Inicializar la configuración regional
    _getChartData();
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
              child: _chartData.isEmpty
                  ? const Center(child: Text('No hay clientes disponibles'))
                  : _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    ChartData chartData = ChartData(
      dataRows: [
        _chartData.map((e) => e.value).toList(),
      ],
      xUserLabels: _chartData.map((e) => e.label).toList(),
      dataRowsLegends: const ["Clientes"],
      chartOptions: const ChartOptions(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 0 ? constraints.maxWidth : 300;
        return SizedBox(
          width: width.toDouble(),
          height: 300,
          child: VerticalBarChart(
            painter: VerticalBarChartPainter(
              verticalBarChartContainer:
                  VerticalBarChartTopContainer(chartData: chartData),
            ),
          ),
        );
      },
    );
  }
}

class _ChartData {
  _ChartData(this.label, this.value);
  final String label;
  final double value;
}
