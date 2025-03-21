import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' show ImageByteFormat;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData, Uint8List;

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
  final GlobalKey _chartKey = GlobalKey();
  Uint8List? _logoBytes;
  Uint8List? _cachedChartImage;
  DateTime? _cachedChartMonth;

  @override
  void initState() {
    super.initState();
    _loadLogo();
    _getChartData();
  }

  Future<void> _loadLogo() async {
    final data = await rootBundle.load('assets/logo_PLC.jpg');
    _logoBytes = data.buffer.asUint8List();
  }

  Future<Uint8List> _captureChart() async {
    final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception("Widget no renderizado");

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
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
          build: (context) => _buildPdfContent(chartImage),
          footer: (context) => _buildPdfFooter(context),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Promedio_Clientes.pdf',
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
            fit: pw.BoxFit.contain,
          ),
        ),
        pw.Text('Premium Logistics Cargo',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text('Reporte emitido el: $formattedDate',
            style: pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  List<pw.Widget> _buildPdfContent(Uint8List chartImage) {
    return [
      pw.Image(pw.MemoryImage(chartImage)),
      pw.SizedBox(height: 20),
      pw.Table(
        columnWidths: {
          0: const pw.FixedColumnWidth(150),
          1: const pw.FixedColumnWidth(100),
        },
        border: pw.TableBorder.all(color: PdfColors.grey),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue),
            children: ['Modalidad', 'Porcentaje']
                .map((header) => _buildTableCell(header, isHeader: true))
                .toList(),
          ),
          ..._chartData.map((data) => pw.TableRow(
            children: [
              _buildTableCell(data.mode),
              _buildTableCell('${data.average.toStringAsFixed(1)}%'),
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

    if (!mounted) return; // Ensure the widget is still in the tree before updating state

    if (total == 0) {
      if(mounted){
        setState(() {
          _chartData = [];
          _isLoading = false;
        });
      }
      return;
    }

    List<_ChartData> chartData = [
      _ChartData('Aereo', (aereoCount / total) * 100, Colors.blue),
      _ChartData('Maritimo', (maritimoCount / total) * 100, Colors.green),
    ];

    if (!mounted) return; // Ensure the widget is still in the tree before updating state
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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: generatePdf,
          ),
        ],
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
                      RepaintBoundary( // Move RepaintBoundary here
                        key: _chartKey,
                        child: SizedBox(
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