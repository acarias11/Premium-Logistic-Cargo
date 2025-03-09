import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:plc_pruebas/services/firestore.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';

import 'package:sidebarx/sidebarx.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  _WarehousePageState createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 2);
  String _searchTerm = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(
        'es', null); // Inicializar la configuración regional
  }

  Stream<QuerySnapshot> getWare() {
    return firestoreService.getWarehouses();
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Sujeta a cambio';
    }
    DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<String> getEstatusNameById(String id) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('Estatus').doc(id).get();
    return snapshot.exists
        ? (snapshot['Nombre'] ?? 'Desconocido')
        : 'Desconocido';
  }

  Future<String> getModalidadNameById(String id) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('Modalidad').doc(id).get();
    return snapshot.exists
        ? (snapshot['Nombre'] ?? 'Desconocido')
        : 'Desconocido';
  }

  Future<String> getClientFullName(String clientId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('Clientes')
        .doc(clientId)
        .get();
    if (snapshot.exists && snapshot.data() != null) {
      Map<String, dynamic> clientData = snapshot.data() as Map<String, dynamic>;
      String nombre = clientData['nombre'] ?? clientData['Nombre'] ?? '';
      String apellido = clientData['apellido'] ?? clientData['Apellido'] ?? '';
      String fullName = ('$nombre $apellido').trim();
      return fullName.isEmpty ? 'Desconocido' : fullName;
    }
    return 'Desconocido';
  }

  Future<void> generatePdf() async {
    try {
      final pdf = pw.Document();

      final warehouses = await _firestore.collection('Warehouse').get();

      final headers = [
        'WarehouseID',
        'CargaID',
        'Nombre del cliente',
        'Dirección',
        'Estatus',
        'Fecha de creación',
        'Modalidad',
        'Peso',
        'Paquetes'
      ];

      final data = await Future.wait(warehouses.docs.map((doc) async {
        final data = doc.data();
        final fecha = (data['fecha'] as Timestamp).toDate();
        return [
          data['warehouse_id'] ?? 'Desconocido',
          data['carga_id'] ?? 'Desconocido',
          await getClientFullName(data['cliente_id'] ?? '') ?? 'Desconocido',
          data['direccion'] ?? 'Desconocido',
          data['estatus_id'] ?? 'Desconocido',
          DateFormat('dd/MM/yyyy').format(fecha),
          data['modalidad'] ?? 'Desconocido',
          data['peso_total']?.toString() ?? 'Desconocido',
          data['piezas']?.toString() ?? 'Desconocido',
        ];
      }).toList());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return [
              pw.Text(
                "Reporte de warehouses",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),  // WarehouseID
                  1: const pw.FixedColumnWidth(80),  // CargaID
                  2: const pw.FixedColumnWidth(80),  // Nombre del cliente
                  3: const pw.FixedColumnWidth(80),  // Dirección
                  4: const pw.FixedColumnWidth(60),  // Estatus
                  5: const pw.FixedColumnWidth(60),  // Fecha de creación
                  6: const pw.FixedColumnWidth(60),  // Modalidad
                  7: const pw.FixedColumnWidth(40),  // Peso
                  8: const pw.FixedColumnWidth(40),  // Paquetes
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
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Reporte_de_Warehouses.pdf',
      );
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(selectedIndex: 2, controller: _sidebarXController),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text(
          'Warehouse',
          style: TextStyle(color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por warehouse_id, carga_id o cliente_id',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.blue.shade800.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value.toLowerCase();
                });
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: generatePdf,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: generatePdf,
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: getWare(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Error al obtener los almacenes',
                      style: TextStyle(color: Colors.white)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No hay almacenes disponibles',
                      style: TextStyle(color: Colors.white)));
            }

            var filteredDocs = snapshot.data!.docs.where((document) {
              Map<String, dynamic>? data =
                  document.data() as Map<String, dynamic>?;
              if (data == null) return false;

              String whId = document['warehouse_id'].toString().toLowerCase();
              String cargaId = data['carga_id']?.toString().toLowerCase() ?? '';
              String clientId =
                  data['cliente_id']?.toString().toLowerCase() ?? '';

              return _searchTerm.isEmpty ||
                  whId.contains(_searchTerm) ||
                  cargaId.contains(_searchTerm) ||
                  clientId.contains(_searchTerm);
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
                      DataColumn(label: Text('WarehouseID')),
                      DataColumn(label: Text('CargaID')),
                      DataColumn(label: Text('Nombre del cliente')),
                      DataColumn(label: Text('Dirección')),
                      DataColumn(label: Text('Estatus')),
                      DataColumn(label: Text('Fecha de creación')),
                      DataColumn(label: Text('Modalidad')),
                      DataColumn(label: Text('Peso')),
                      DataColumn(label: Text('Paquetes')),
                    ],
                    source: _DataSource(filteredDocs, context, getClientFullName, getEstatusNameById, getModalidadNameById, formatDate),
                    rowsPerPage: 10,
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
    );
  }
}

class _DataSource extends DataTableSource {
  final List<DocumentSnapshot> _docs;
  final BuildContext _context;

  final Future<String> Function(String) getClientFullName;
  final Future<String> Function(String) getEstatusNameById;
  final Future<String> Function(String) getModalidadNameById;
  final String Function(Timestamp?) formatDate;

  _DataSource(this._docs, this._context, this.getClientFullName, this.getEstatusNameById, this.getModalidadNameById, this.formatDate);

  @override
  DataRow getRow(int index) {
    final document = _docs[index];
    final data = document.data() as Map<String, dynamic>?;

    if (data == null) {
      return const DataRow(cells: [DataCell(Text('Error al cargar datos'))]);
    }

    return DataRow(cells: [
      DataCell(Text(document['warehouse_id'])),
      DataCell(Text(data['carga_id']?.toString() ?? 'Desconocido')),
      DataCell(FutureBuilder(
        future: getClientFullName(data['cliente_id'] ?? ''),
        builder: (context, snapshot) =>
            Text(snapshot.data ?? 'Cargando...'),
      )),
      DataCell(Text(data['direccion'] ?? 'Desconocido')),
      DataCell(FutureBuilder(
        future: getEstatusNameById(data['estatus_id'] ?? ''),
        builder: (context, snapshot) =>
            Text(snapshot.data ?? 'Cargando...'),
      )),
      DataCell(Text(formatDate(data['fecha']))),
      DataCell(FutureBuilder(
        future: getModalidadNameById(data['modalidad'] ?? ''),
        builder: (context, snapshot) =>
            Text(snapshot.data ?? 'Cargando...'),
      )),
      DataCell(Text(data['peso_total'].toString())),
      DataCell(Text(data['piezas'].toString())),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _docs.length;

  @override
  int get selectedRowCount => 0;
}
