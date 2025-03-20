import 'dart:ui' show ImageByteFormat;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';

class PdfData {
  final List<List<String>> activeData;
  final List<List<String>> inactiveData;
  final Uint8List logoBytes;
  final Uint8List chartImage;
  final String formattedDate;

  PdfData({
    required this.activeData,
    required this.inactiveData,
    required this.logoBytes,
    required this.chartImage,
    required this.formattedDate,
  });
}

Future<Uint8List> generatePdfBytes(PdfData data) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a3,
      margin: const pw.EdgeInsets.all(16),
      // Dentro de la función generatePdfBytes
      header: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Container(
            height: 150,
            width: 500,
            child: pw.Image(
              pw.MemoryImage(data.logoBytes),
              fit: pw.BoxFit.contain, // Mantiene la relación de aspecto
            ),
          ),
          pw.Text(
            'Premium Logistics Cargo',
            style: pw.TextStyle(
              fontSize: 24, // Tamaño aumentado para mejor legibilidad
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Reporte emitido el: ${data.formattedDate}',
            style: pw.TextStyle(
              fontSize: 14, // Tamaño aumentado
              color: PdfColors.grey,
            ),
          ),
        ],
      ),
      build: (pw.Context context) => [
        pw.Text(
          'Clientes Activos/Inactivos',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Image(pw.MemoryImage(data.chartImage)), // Tamaño automático
        pw.SizedBox(height: 20),
        _buildTable('Clientes Activos', data.activeData),
        pw.SizedBox(height: 20),
        _buildTable('Clientes Inactivos', data.inactiveData),
      ],
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10),
        decoration: const pw.BoxDecoration(color: PdfColors.blue),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  'Premium Logistics Cargo',
                  style: pw.TextStyle(fontSize: 18, color: PdfColors.white),
                ),
              ),
            ),
            pw.Text(
              '${context.pageNumber}/${context.pagesCount}',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.white),
            ),
          ],
        ),
      ),
    ),
  );

  return pdf.save();
}

pw.Widget _buildTable(String title, List<List<String>> data) {
  return pw.Column(
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        columnWidths: {
          0: const pw.FixedColumnWidth(100),
          1: const pw.FixedColumnWidth(150),
          2: const pw.FixedColumnWidth(100),
        },
        border: pw.TableBorder.all(color: PdfColors.grey),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue),
            children: ['ID del cliente', 'Nombre', 'Teléfono'].map((header) => pw.Container(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                header,
                style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
              ),
            )).toList(),
          ),
          ...data.map((row) => pw.TableRow(
            children: row.map((cell) => pw.Container(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(cell, style: const pw.TextStyle(fontSize: 12)),
            )).toList(),
          )),
        ],
      ),
    ],
  );
}

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
  List<Map<String, dynamic>> _clientesActivos = [];
  List<Map<String, dynamic>> _clientesInactivos = [];
  Uint8List? _logoBytes;
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadLogo();
    _loadData();
  }

  Future<void> _loadLogo() async {
    final data = await rootBundle.load('assets/logo_PLC.jpg');
    _logoBytes = data.buffer.asUint8List();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      final start = Timestamp.fromDate(firstDay);
      final end = Timestamp.fromDate(nextMonth);

      final [clientes, warehouses] = await Future.wait([
        FirebaseFirestore.instance
            .collection('Clientes')
            .where('fecha', isGreaterThanOrEqualTo: start)
            .where('fecha', isLessThan: end)
            .get(),
        FirebaseFirestore.instance
            .collection('Warehouse')
            .where('fecha', isGreaterThanOrEqualTo: start)
            .where('fecha', isLessThan: end)
            .get(),
      ]);

      final clientesIds = _processClientes(clientes.docs);
      final warehouseIds = _processWarehouses(warehouses.docs);
      
      final activeIds = clientesIds.intersection(warehouseIds);
      
      _clientesActivos = _filterClients(clientes.docs, activeIds);
      _clientesInactivos = _filterClients(clientes.docs, clientesIds.difference(activeIds));
      
      _updateChartData(activeIds.length, clientesIds.length);
      
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    }
    setState(() => _isLoading = false);
  }

  Set<String> _processClientes(List<QueryDocumentSnapshot> docs) {
    return docs
        .where((doc) => doc['cliente_id']?.toString().trim().isNotEmpty ?? false)
        .map((doc) => doc['cliente_id'].toString().trim())
        .toSet();
  }

  Set<String> _processWarehouses(List<QueryDocumentSnapshot> docs) {
    return docs
        .where((doc) => doc['cliente_id']?.toString().trim().isNotEmpty ?? false)
        .map((doc) => doc['cliente_id'].toString().trim())
        .toSet();
  }

  List<Map<String, dynamic>> _filterClients(List<QueryDocumentSnapshot> docs, Set<String> ids) {
    return docs
        .where((doc) => ids.contains(doc['cliente_id']?.toString().trim()))
        .map((doc) => {
          'cliente_id': doc['cliente_id'].toString(),
          'nombre': doc['nombre']?.toString().trim() ?? 'Desconocido',
          'telefono': doc['telefono']?.toString().trim() ?? 'Desconocido',
        })
        .toList();
  }

  void _updateChartData(int activeCount, int total) {
    if (total == 0) {
      _chartData = [];
      return;
    }
    
    final activePercentage = (activeCount / total) * 100;
    setState(() {
      _chartData = [
        _ChartData('Activos', activePercentage),
        _ChartData('Inactivos', 100 - activePercentage),
      ];
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() => _selectedMonth = picked);
      _loadData();
    }
  }

  Future<Uint8List> _captureChart() async {
    final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception("Widget no renderizado");
    
    final image = await boundary.toImage(pixelRatio: 0.7); // Reducción de resolución
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> generatePdf() async {
    try {
      final chartImage = await _captureChart();
      final pdfData = PdfData(
        activeData: _clientesActivos.map((c) => [c['cliente_id'] as String, c['nombre'] as String, c['telefono'] as String]).toList(),
        inactiveData: _clientesInactivos.map((c) => [c['cliente_id'] as String, c['nombre'] as String, c['telefono'] as String]).toList(),
        logoBytes: _logoBytes!,
        chartImage: chartImage,
        formattedDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      );

      final pdfBytes = await compute(generatePdfBytes, pdfData);
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
      
    } catch (e) {
      print('Error al generar PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text('Clientes Activos/Inactivos', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isLoading ? null : generatePdf,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.orange.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white)));
    
    return Column(
      children: [
        _buildMonthSelector(),
        Expanded(child: _buildChartOrMessage()),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade800,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onPressed: () => _selectMonth(context),
        child: Text(
          'Mes: ${DateFormat('MMM yyyy').format(_selectedMonth)}',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildChartOrMessage() {
    if (_chartData.isEmpty) {
      return const Center(
        child: Text('No hay datos disponibles', style: TextStyle(color: Colors.white)),
      );
    }

    return RepaintBoundary(
      key: _chartKey,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0), // Agrega margen inferior
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
                          'Clientes Activos/Inactivos',
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
                                leading: Icon(
                                  Icons.circle,
                                  color: data.label == 'Activos' ? Colors.green : Colors.red,
                                ),
                                title: Text(data.label, style: const TextStyle(fontSize: 14)),
                                trailing: Text('${data.value.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14)),
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
                        color: data.label == 'Activos' ? Colors.green : Colors.red,
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
      ),
    );
  }

  Widget _buildTableView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Clientes Activos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(color: Colors.black))),
                DataColumn(label: Text('Nombre', style: TextStyle(color: Colors.black))),
                DataColumn(label: Text('Teléfono', style: TextStyle(color: Colors.black))),
              ],
              rows: _clientesActivos
                  .map(
                    (cliente) => DataRow(
                      cells: [
                        DataCell(Text(cliente['cliente_id'], style: const TextStyle(color: Colors.black))),
                        DataCell(Text(cliente['nombre'], style: const TextStyle(color: Colors.black))),
                        DataCell(Text(cliente['telefono'], style: const TextStyle(color: Colors.black))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    return Column(
      children: [
        const Text(
          'Distribución de Clientes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: _chartData.map((data) {
                final isActive = data.label == 'Activos';
                return PieChartSectionData(
                  value: data.value,
                  title: '${data.value.toStringAsFixed(1)}%',
                  color: isActive ? Colors.green : Colors.red,
                  titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  
  _ChartData(this.label, this.value);
}