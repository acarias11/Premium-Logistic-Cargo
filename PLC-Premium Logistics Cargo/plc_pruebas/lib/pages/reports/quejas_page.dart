import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';

class QuejasPage extends StatefulWidget {
  const QuejasPage({super.key});

  @override
  _QuejasPageState createState() => _QuejasPageState();
}

class _QuejasPageState extends State<QuejasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 6);
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null); // Inicializar la configuración regional
  }

  Stream<QuerySnapshot> getQuejas() {
    return _firestore.collection('Quejas').snapshots();
  }

  Future<String> getClientName(String clientId) async {
    try {
      DocumentSnapshot clientSnapshot =
          await _firestore.collection('Clientes').doc(clientId).get();
      if (clientSnapshot.exists) {
        Map<String, dynamic> clientData =
            clientSnapshot.data() as Map<String, dynamic>;
        return '${clientData['nombre']} ${clientData['apellido']}';
      }
    } catch (e) {
      print('Error al obtener el nombre del cliente: $e');
    }
    return 'Desconocido';
  }

  Future<void> generatePdf() async {
    try {
      final pdf = pw.Document();
      final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final quejas = await _firestore.collection('Quejas').get();

      final imageLogo = pw.MemoryImage(
        (await rootBundle.load('assets/logo_PLC.jpg')).buffer.asUint8List(),
      );

      final headers = [
        'Clasificación',
        'Razón',
        'Cliente'
      ];

      final data = await Future.wait(quejas.docs.map((doc) async {
        final data = doc.data();
        final clientName = await getClientName(data['cliente_id'] ?? 'Desconocido');
        return [
          data['clasificacion'] ?? 'Sin Clasificación',
          data['razon'] ?? 'Sin Razón',
          clientName,
        ];
      }).toList());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3,
          margin: const pw.EdgeInsets.all(16),
          header: (context) { //ENCABEZADO DEL PDF
            return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(imageLogo, height: 150, width: 500),
                  pw.Text(
                    'Premium Logistics Cargo',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Reporte emitido el: $formattedDate',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              );
           },
          build: (pw.Context context) {
            return [
              pw.Text(
                "Reporte de Quejas",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),  // Clasificación
                  1: const pw.FixedColumnWidth(80),  // Razón
                  2: const pw.FixedColumnWidth(80),  // Cliente
                },
                border: pw.TableBorder.all(color: PdfColors.grey),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue),
                    children: headers.map((header) => pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        header,
                        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                        softWrap: true,
                      ),
                    )).toList(),
                  ),
                  ...data.map((row) {
                    return pw.TableRow(
                      children: row.map((cell) => pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          cell.toString(),
                          style: const pw.TextStyle(fontSize: 8),
                          softWrap: true,
                        ),
                      )).toList(),
                    );
                  }),
                ],
              )
            ];
          },
          footer: (pw.Context context) {
            final currentPage = context.pageNumber;
            final totalPages = context.pagesCount;
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              decoration: const pw.BoxDecoration(color: PdfColors.blue),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Nombre de la compañía centrado
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'Premium Logistics Cargo',
                        style: pw.TextStyle(fontSize: 18, color: PdfColors.white),
                      ),
                    ),
                  ),              // Número de página en el formato "1/5"
                  pw.Text(
                    '$currentPage/$totalPages',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.white),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Reporte_de_Quejas.pdf',
      );
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(selectedIndex: 4, controller: _sidebarXController),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text(
          'Quejas',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre',
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.blue.shade800.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value.toUpperCase();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getQuejas(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text(
                      'Error al obtener las quejas',
                      style: TextStyle(color: Colors.white),
                    ));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text(
                      'No hay quejas disponibles',
                      style: TextStyle(color: Colors.white),
                    ));
                  }
                  var filteredDocs =
                      snapshot.data!.docs.where((DocumentSnapshot document) {
                    Map<String, dynamic>? data =
                        document.data() as Map<String, dynamic>?;
                    if (data == null) return false;
                    String numeroIdentidad =
                        data['razon']?.toString() ?? '';
                    return numeroIdentidad.contains(_searchText);
                  }).toList();
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: PaginatedDataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: 600,
                          dataRowHeight: 60,
                          headingRowHeight: 40,
                          headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                          columns: const [
                            DataColumn2(label: Text('Clasificación')),
                            DataColumn2(label: Text('Razón')),
                            DataColumn2(label: Text('Cliente')),
                          ],
                          source: _QuejasDataSource(filteredDocs, getClientName),
                          rowsPerPage: _rowsPerPage,
                          availableRowsPerPage: const [10, 20, 50],
                          onRowsPerPageChanged: (value) {
                            setState(() {
                              _rowsPerPage = value!;
                            });
                          },
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
    );
  }
}

class _QuejasDataSource extends DataTableSource {
  final List<DocumentSnapshot> _docs;
  final Future<String> Function(String) getClientName;

  _QuejasDataSource(this._docs, this.getClientName);

  @override
  DataRow getRow(int index) {
    final document = _docs[index];
    final data = document.data() as Map<String, dynamic>?;

    if (data == null) {
      return const DataRow(cells: [DataCell(Text('Error al cargar datos'))]);
    }

    return DataRow(cells: [
      DataCell(Text(data['clasificacion']?.toString() ?? 'Sin Clasificación')),
      DataCell(Text(data['razon']?.toString() ?? 'Sin Razón')),
      DataCell(FutureBuilder<String>(
        future: getClientName(data['cliente_id']?.toString() ?? 'Desconocido'),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Cargando...');
          }
          if (snapshot.hasError) {
            return const Text('Error');
          }
          return Text(snapshot.data ?? 'Desconocido');
        },
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _docs.length;

  @override
  int get selectedRowCount => 0;
}