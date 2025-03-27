import 'dart:ui' show ImageByteFormat;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;

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
  final GlobalKey _chartKey = GlobalKey();
  Uint8List? _logoBytes;
  List<Map<String, dynamic>> _clientesRegistrados = [];
  Uint8List? _cachedChartImage;
  DateTime? _cachedChartMonth;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _loadLogo();
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

  Future<void> _loadLogo() async {
    final data = await rootBundle.load('assets/logo_PLC.jpg');
    _logoBytes = data.buffer.asUint8List();
  }

  Future<void> _getChartData() async {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

    final snapshot = await _firestore
        .collection('Clientes')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('fecha', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    final clientesPorDia = <int, int>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['fecha'] is Timestamp) {
        final fecha = (data['fecha'] as Timestamp).toDate();
        clientesPorDia[fecha.day] = (clientesPorDia[fecha.day] ?? 0) + 1;
      }
    }

    final chartData = clientesPorDia.entries
        .map((entry) => _ChartData(entry.key.toString(), entry.value.toDouble()))
        .toList()
        ..sort((a, b) => int.parse(a.label).compareTo(int.parse(b.label)));

    final clientesData = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'cliente_id': doc.id,
        'nombre': data['nombre'] ?? 'Desconocido',
        'telefono': data['telefono'] ?? 'Desconocido',
        'fecha': (data['fecha'] as Timestamp).toDate(),
      };
    }).toList();

    setState(() {
      _chartData = chartData;
      _clientesRegistrados = clientesData;
      if (_cachedChartMonth?.month != _selectedMonth.month) {
        _cachedChartImage = null;
        _cachedChartMonth = _selectedMonth;
      }
    });
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
        _getChartData();
      });
    }
  }

  Future<Uint8List> _captureChart() async {
    if (_cachedChartImage != null) return _cachedChartImage!;
    
    final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception("Widget no renderizado");
    
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    _cachedChartImage = bytes;
    return bytes;
  }

  Future<void> generatePdf() async {
    try {
      final chartImage = await _captureChart();
      final pdf = pw.Document();
      final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3,
          margin: const pw.EdgeInsets.all(16),
          header: (context) => _buildPdfHeader(formattedDate),
          build: (context) => _buildPdfContent(chartImage, context),
          footer: (context) => _buildPdfFooter(context),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Clientes_Registrados_Mensuales.pdf',
      );
    } catch (e) {
      print('Error al generar el PDF: $e');
    }
  }

  pw.Widget _buildPdfHeader(String formattedDate) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
          pw.Container(
            height: 150,
            width: 500,
            child: pw.Image(
              pw.MemoryImage(_logoBytes!),
              fit: pw.BoxFit.contain, // Mantiene la relación de aspecto
            ),
          ),
        pw.Text('Premium Logistics Cargo', 
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text('Reporte emitido el: $formattedDate', 
            style: pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  List<pw.Widget> _buildPdfContent(Uint8List chartImage, pw.Context context) {
    return [
      // Display the chart at the top
      pw.Image(pw.MemoryImage(chartImage)),
      pw.SizedBox(height: 20),
      // Display the generated table below the chart
      pw.Table(
        columnWidths: {
          0: const pw.FixedColumnWidth(100),
          1: const pw.FixedColumnWidth(150),
          2: const pw.FixedColumnWidth(100),
          3: const pw.FixedColumnWidth(100),
        },
        border: pw.TableBorder.all(color: PdfColors.grey),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue),
            children: ['ID Cliente', 'Nombre', 'Teléfono', 'Fecha Registro']
                .map((header) => _buildTableCell(header, isHeader: true))
                .toList(),
          ),
          ..._clientesRegistrados.map((cliente) => pw.TableRow(
            children: [
              _buildTableCell(cliente['cliente_id'].toString()),
              _buildTableCell(cliente['nombre']),
              _buildTableCell(cliente['telefono']),
              _buildTableCell(DateFormat('dd/MM/yyyy').format(cliente['fecha'])),
            ],
          )),
        ],
      ),
    ];
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(
            fontSize: 12,
            color: isHeader ? PdfColors.white : PdfColors.black,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          )),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(color: PdfColors.blue),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Center(
              child: pw.Text('Premium Logistics Cargo',
                  style: pw.TextStyle(fontSize: 18, color: PdfColors.white)),
            ),
          ),
          pw.Text('${context.pageNumber}/${context.pagesCount}',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 50, 110),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: generatePdf,
            color: Colors.white,
          ),
        ],
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
                      'Clientes registrados en el mes seleccionado',
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
                          'Seleccionar Mes: ${DateFormat.yMMM('es').format(_selectedMonth)}'),
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
                              'Clientes por Día',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: _chartData.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No hay datos disponibles',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: _chartData.length,
                                            itemBuilder: (context, index) {
                                              final data = _chartData[index];
                                              final date = DateTime(
                                                _selectedMonth.year,
                                                _selectedMonth.month,
                                                int.parse(data.label),
                                              );
                                              final formattedDate =
                                                  DateFormat('dd MMM yyyy', 'es').format(date);
                                              return ListTile(
                                                title: Text(formattedDate),
                                                trailing: Text(
                                                  '${data.value.toInt()} clientes',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Fila para el total
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: ListTile(
                                            tileColor: Colors.orange.shade100,
                                            title: const Text(
                                              'Total de Clientes',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            trailing: Text(
                                              '${_chartData.fold<int>(0, (sum, item) => sum + item.value.toInt())} clientes',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
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
                        child: _buildChart(),
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

  Widget _buildChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título del gráfico
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Clientes Registrados por Día',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: RepaintBoundary(
            key: _chartKey,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _chartData.isNotEmpty
                    ? _chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1
                    : 1,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = _chartData[group.x.toInt()].label;
                      return BarTooltipItem(
                        'Día $day\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '${rod.toY.toInt()} clientes',
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
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _chartData.length) {
                          return Text(
                            'Día ${_chartData[index].label}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink(); // No mostrar nada para valores fuera de rango
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        // Mostrar solo números enteros
                        if (value % 1 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const SizedBox.shrink(); // No mostrar nada para valores no enteros
                      },
                    ),
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(right: 6.0),
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          'C\nL\nI\nE\nN\nT\nE\nS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
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
                                color: index == touchedIndex
                                    ? Colors.orange
                                    : Colors.blue.shade700,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: _chartData.isNotEmpty
                                      ? _chartData
                                              .map((e) => e.value)
                                              .reduce((a, b) => a > b ? a : b) +
                                          1
                                      : 1,
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
        ),
        // Leyenda
        const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(Icons.square, color: Colors.blue, size: 16),
              SizedBox(width: 4),
              Text(
                'Clientes registrados',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
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