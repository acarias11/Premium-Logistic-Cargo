import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' show ImageByteFormat;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:plc_pruebas/pages/provider/theme_provider.dart' show ThemeProvider;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData, Uint8List;
import 'package:provider/provider.dart';
import 'package:plc_pruebas/pages/provider/theme_provider.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final _isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDarkMode
            ? const Color.fromARGB(255, 0, 0, 0)
            : const Color.fromARGB(255, 10, 50, 110),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: generatePdf,
            color: Colors.white,
          ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.nightlight_round : Icons.wb_sunny),
            onPressed: () {
              setState(() {
                themeProvider.toggleTheme(); // Alterna el estado global del tema
              });
            },
            color: Colors.white,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [const Color.fromARGB(255, 0, 0, 0), const Color.fromARGB(255, 0, 0, 0)]
                : [const Color.fromARGB(255, 10, 50, 110), const Color.fromARGB(255, 10, 50, 110)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: _isDarkMode ? Color.fromRGBO(30, 30, 30, 1) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Promedio de Clientes por Modalidad',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _selectMonth(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isDarkMode ? Colors.grey.shade800 : Colors.blue,
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
                        // Data Table Section
                        Expanded(
                          flex: 1,
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: _isDarkMode ? Color.fromRGBO(30, 30, 30, 1) : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resumen de Modalidades',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _chartData.length,
                                      itemBuilder: (context, index) {
                                        final data = _chartData[index];
                                        return Container(
                                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                                          decoration: BoxDecoration(
                                            color: _isDarkMode
                                                ? Colors.grey.shade800
                                                : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: ListTile(
                                            leading: Icon(Icons.circle, color: data.color),
                                            title: Text(
                                              data.mode,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: _isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            trailing: Text(
                                              '${data.average.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: _isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
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
                            color: _isDarkMode ? Color.fromRGBO(30, 30, 30, 1) : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Distribución de Clientes por Modalidad',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: RepaintBoundary(
                                      key: _chartKey,
                                      child: PieChart(
                                        PieChartData(
                                          borderData: FlBorderData(show: false),
                                          sectionsSpace: 0,
                                          centerSpaceRadius: 40,
                                          sections: _chartData.map((data) {
                                            return PieChartSectionData(
                                              color: data.color,
                                              value: data.average,
                                              title: '${data.average.toStringAsFixed(1)}%',
                                              radius: 120,
                                              titleStyle: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
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
}

class _ChartData {
  _ChartData(this.mode, this.average, this.color);
  final String mode;
  final double average;
  final Color color;
}