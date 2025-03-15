import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:plc_pruebas/services/firestore.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/date_symbol_data_local.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Variable para el término de búsqueda y filas por página
  String _searchTerm = '';
  final int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  List<DocumentSnapshot> _currentFilteredDocs = [];

  // GlobalKey para acceder al estado interno del widget de la tabla y obtener la página actual para el PDF.
  final GlobalKey<_WarehouseTableState> warehouseTableKey =
      GlobalKey<_WarehouseTableState>();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
  }

  // Obtiene los almacenes desde Firestore
  Stream<QuerySnapshot> getWare() {
    return firestoreService.getWarehouses();
  }

  // Formatea la fecha de un Timestamp
  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Sujeta a cambio';
    DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Obtiene el nombre completo del cliente
  Future<String> getClientFullName(String clientId) async {
    DocumentSnapshot snapshot =
        await _firestore.collection('Clientes').doc(clientId).get();
    if (snapshot.exists && snapshot.data() != null) {
      Map<String, dynamic> clientData =
          snapshot.data() as Map<String, dynamic>;
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
      final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
      // Se obtiene la página actual desde el estado del widget WarehouseTable
      final int currentPage = warehouseTableKey.currentState?.currentPage ?? 0;
      final int start = currentPage;
      final int end = (currentPage + _rowsPerPage) > _currentFilteredDocs.length
          ? _currentFilteredDocs.length
          : (currentPage + _rowsPerPage);
      final List<DocumentSnapshot> currentPageDocs =
          _currentFilteredDocs.sublist(start, end);

      // Cargar el logo desde los assets
      final imageLogo = pw.MemoryImage(
        (await rootBundle.load('assets/logo_PLC.jpg')).buffer.asUint8List(),
      );

      // Encabezados de la tabla PDF
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

      // Construir los datos a mostrar (sólo los de la página actual)
      final data = await Future.wait(currentPageDocs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final fecha = data['fecha'] as Timestamp? ?? Timestamp.now();
        return [
          data['warehouse_id'] ?? 'Desconocido',
          data['carga_id'] ?? 'Desconocido',
          await getClientFullName(data['cliente_id'] ?? ''),
          data['direccion'] ?? 'Desconocido',
          await firestoreService.getEstatusNameById(data['estatus_id'] ?? ''),
          DateFormat('dd/MM/yyyy').format(fecha.toDate()),
          await firestoreService.getModalidadNameById(data['modalidad'] ?? ''),
          data['peso_total']?.toString() ?? 'Desconocido',
          data['piezas']?.toString() ?? 'Desconocido',
        ];
      }).toList());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3,
          margin: const pw.EdgeInsets.all(16),
          // Encabezado que se repite en cada página : header
          header: (context) {
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
          // Pie de página: footer
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
          build: (context) { //build Contenido
            return [
              pw.Text(
                "Reporte de warehouses",
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              // Uso de Table.fromTextArray para que se divida automáticamente en páginas
              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
                cellStyle: pw.TextStyle(fontSize: 12),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(color: PdfColors.grey),
              ),
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
        title: const Text('Warehouse', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'Buscar por warehouse_id, carga_id o cliente_id',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.blue.shade800.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              // Al cambiar el texto, actualizamos el término de búsqueda
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

            // Filtrar documentos según el término de búsqueda
            var filteredDocs = snapshot.data!.docs.where((document) {
              Map<String, dynamic>? data =
                  document.data() as Map<String, dynamic>?;
              if (data == null) return false;
              String whId =
                  document['warehouse_id'].toString().toLowerCase();
              String cargaId =
                  data['carga_id']?.toString().toLowerCase() ?? '';
              String clientId =
                  data['cliente_id']?.toString().toLowerCase() ?? '';
              return _searchTerm.isEmpty ||
                  whId.contains(_searchTerm) ||
                  cargaId.contains(_searchTerm) ||
                  clientId.contains(_searchTerm);
            }).toList();

            // Actualizamos la lista global de documentos filtrados
            _currentFilteredDocs = filteredDocs;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: WarehouseTable(
                    key: warehouseTableKey,
                    docs: filteredDocs,
                    rowsPerPage: _rowsPerPage,
                    getClientFullName: getClientFullName,
                    getEstatusNameById: firestoreService.getEstatusNameById,
                    getModalidadNameById: firestoreService.getModalidadNameById,
                    formatDate: formatDate,
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

class WarehouseTable extends StatefulWidget {
  final List<DocumentSnapshot> docs;
  final int rowsPerPage;
  final Future<String> Function(String) getClientFullName;
  final Future<String> Function(String) getEstatusNameById;
  final Future<String> Function(String) getModalidadNameById;
  final String Function(Timestamp?) formatDate;

  const WarehouseTable({
    super.key,
    required this.docs,
    required this.rowsPerPage,
    required this.getClientFullName,
    required this.getEstatusNameById,
    required this.getModalidadNameById,
    required this.formatDate,
  });

  @override
  _WarehouseTableState createState() => _WarehouseTableState();
}

class _WarehouseTableState extends State<WarehouseTable> {
  int _currentPage = 0;

  int get currentPage => _currentPage;

  @override
  Widget build(BuildContext context) {
    return PaginatedDataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 600,
      dataRowHeight: 60,
      headingRowHeight: 40,
      headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold, color: Colors.black),
      columns: const [
        DataColumn(label: Text('WarehouseID')),
        DataColumn(label: Text('Nombre del cliente')),
        DataColumn(label: Text('Dirección')),
        DataColumn(label: Text('Estatus')),
        DataColumn(label: Text('Fecha de creación')),
        DataColumn(label: Text('Modalidad')),
        DataColumn(label: Text('Peso')),
        DataColumn(label: Text('Paquetes')),
      ],
      source: _WarehousesDataSource(
        widget.docs,
        context,
        widget.getClientFullName,
        widget.getEstatusNameById,
        widget.getModalidadNameById,
        widget.formatDate,
      ),
      rowsPerPage: widget.rowsPerPage,
      availableRowsPerPage: const [10, 20, 50],
      initialFirstRowIndex: _currentPage,
      onRowsPerPageChanged: (value) {
        // Aquí podrías actualizar rowsPerPage si lo deseas.
      },
      onPageChanged: (firstRowIndex) {
        setState(() {
          _currentPage = firstRowIndex;
        });
      },
    );
  }
}

class _WarehousesDataSource extends DataTableSource {
  final List<DocumentSnapshot> _docs;
  final BuildContext _context;
  final Future<String> Function(String) getClientFullName;
  final Future<String> Function(String) getEstatusNameById;
  final Future<String> Function(String) getModalidadNameById;
  final String Function(Timestamp?) formatDate;

  _WarehousesDataSource(
    this._docs,
    this._context,
    this.getClientFullName,
    this.getEstatusNameById,
    this.getModalidadNameById,
    this.formatDate,
  );

  @override
  DataRow getRow(int index) {
    final document = _docs[index];
    final data = document.data() as Map<String, dynamic>?;

    if (data == null) {
      return const DataRow(
          cells: [DataCell(Text('Error al cargar datos'))]);
    }

    return DataRow(cells: [
      DataCell(Text(data['warehouse_id']?.toString() ?? '')),
      DataCell(FutureBuilder<String>(
        future: getClientFullName(data['cliente_id'] ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Cargando...');
          }
          return Text(snapshot.data ?? 'Desconocido');
        },
      )),
      DataCell(Text(data['direccion'] ?? 'Desconocido')),
      DataCell(FutureBuilder<String>(
        future: getEstatusNameById(data['estatus_id'] ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Cargando...');
          }
          if (snapshot.hasError) {
            return const Text('Error');
          }
          return Text(snapshot.data ?? 'Desconocido');
        },
      )),
      DataCell(Text(formatDate(data['fecha']))),
      DataCell(FutureBuilder<String>(
        future: getModalidadNameById(data['modalidad'] ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Cargando...');
          }
          if (snapshot.hasError) {
            return const Text('Error');
          }
          return Text(snapshot.data ?? 'Desconocido');
        },
      )),
      DataCell(Text(data['peso_total']?.toString() ?? '')),
      DataCell(Text(data['piezas']?.toString() ?? '')),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => _docs.length;
  @override
  int get selectedRowCount => 0;
}
