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
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart'; // Asegúrate de importar esto

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
    initializeDateFormatting('es', null).then((_) {
      // Una vez inicializado, carga los datos
      _loadLogo();
      _loadData();
    });
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
    // Espera un breve momento para asegurarte de que el gráfico esté renderizado
    await Future.delayed(const Duration(milliseconds: 500));

    final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception("El gráfico no está renderizado. Asegúrate de que esté visible en la pantalla.");
    }

    final image = await boundary.toImage(pixelRatio: 2.0); // Ajusta la resolución si es necesario
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> generatePdf() async {
    try {
      // Verifica si el gráfico está renderizado
      if (_chartKey.currentContext == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El gráfico no está visible. Asegúrate de que esté en pantalla.')),
        );
        throw Exception("El gráfico no está renderizado. Intenta nuevamente.");
      }

      // Captura la imagen del gráfico
      final chartImage = await _captureChart();

      // Verifica si el logo está cargado
      if (_logoBytes == null) {
        throw Exception("El logo no está cargado. Verifica el archivo 'assets/logo_PLC.jpg'.");
      }

      // Crea los datos para el PDF
      final pdfData = PdfData(
        activeData: _clientesActivos.map((c) => [c['cliente_id'] as String, c['nombre'] as String, c['telefono'] as String]).toList(),
        inactiveData: _clientesInactivos.map((c) => [c['cliente_id'] as String, c['nombre'] as String, c['telefono'] as String]).toList(),
        logoBytes: _logoBytes!,
        chartImage: chartImage,
        formattedDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      );

      // Genera el PDF
      final pdfBytes = await compute(generatePdfBytes, pdfData);

      // Muestra el PDF
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      // Manejo de errores
      print('Error al generar el PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar el PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 50, 110),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isLoading ? null : generatePdf,
            color: Colors.white
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Clientes activos e inactivos en el mes seleccionado',
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
                                    'Resumen de Casilleros',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Table(
                                    border: TableBorder.all(color: Colors.grey.shade300),
                                    columnWidths: const {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(1),
                                    },
                                    children: [
                                      TableRow(
                                        decoration: BoxDecoration(color: Colors.blue.shade100),
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'Estado',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'Total',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text('Activos'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              '${_clientesActivos.length}',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TableRow(
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text('Inactivos'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              '${_clientesInactivos.length}',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Active Clients Table
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Clientes Activos',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Table(
                                            border: TableBorder.all(color: Colors.grey.shade300),
                                            columnWidths: const {
                                              0: FlexColumnWidth(2),
                                              1: FlexColumnWidth(3),
                                              2: FlexColumnWidth(2),
                                            },
                                            children: [
                                              TableRow(
                                                decoration: BoxDecoration(color: Colors.green.shade100),
                                                children: const [
                                                  Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Text(
                                                      'ID Cliente',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Text(
                                                      'Nombre',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Text(
                                                      'Teléfono',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              ..._clientesActivos.map((cliente) {
                                                return TableRow(
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(cliente['cliente_id']),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(cliente['nombre']),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(cliente['telefono']),
                                                    ),
                                                  ],
                                                );
                                              }),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          // Inactive Clients Table
                                          Text(
                                            'Clientes Inactivos',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Table(
                                            border: TableBorder.all(color: Colors.grey.shade300),
                                            columnWidths: const {
                                              0: FlexColumnWidth(2),
                                              1: FlexColumnWidth(3),
                                              2: FlexColumnWidth(2),
                                            },
                                            children: [
                                              TableRow(
                                                decoration: BoxDecoration(color: Colors.red.shade100),
                                                children: const [
                                                  Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Text(
                                                      'ID Cliente',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Text(
                                                      'Nombre',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Text(
                                                      'Teléfono',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              ..._clientesInactivos.map((cliente) {
                                                return TableRow(
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(cliente['cliente_id']),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(cliente['nombre']),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(cliente['telefono']),
                                                    ),
                                                  ],
                                                );
                                              }),
                                            ],
                                          ),
                                        ],
                                      ),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Distribución de Clientes Activos/Inactivos',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Expanded(
                                    child: RepaintBoundary(
                                      key: _chartKey, // Asegúrate de que este key esté asociado al gráfico
                                      child: SfCircularChart(
                                        legend: Legend(
                                          isVisible: true,
                                          overflowMode: LegendItemOverflowMode.wrap,
                                          position: LegendPosition.bottom,
                                        ),
                                        series: <CircularSeries<_ChartData, String>>[
                                          PieSeries<_ChartData, String>(
                                            dataSource: _chartData,
                                            xValueMapper: (data, _) => data.label,
                                            yValueMapper: (data, _) => data.value,
                                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                                            dataLabelMapper: (data, _) =>
                                                '${data.label}\n${data.value.toStringAsFixed(1)}%',
                                          ),
                                        ],
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
  final String label;
  final double value;
  
  _ChartData(this.label, this.value);
}