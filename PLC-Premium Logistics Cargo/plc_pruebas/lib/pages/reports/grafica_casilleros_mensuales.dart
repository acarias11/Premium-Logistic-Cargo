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
      final data = doc.data() as Map<String, dynamic>;
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
      final data = doc.data() as Map<String, dynamic>;
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
      pw.Text('Clientes Registrados en el Mes Seleccionado',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      pw.Image(pw.MemoryImage(chartImage)),
      pw.SizedBox(height: 20),
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
        title: const Text('Reporte de Casilleros Mensuales'),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: generatePdf,
          ),
        ],
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
                    backgroundColor: Colors.blue,
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
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
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
                                  toY: _chartData.isNotEmpty
                                      ? _chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1
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
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: RotationTransition(
              turns: _animationController,
              child: const Icon(
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