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
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 0);
  String _searchTerm = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null); // Inicializar la configuración regional
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

      final monthName = DateFormat.MMMM('es').format(DateTime.now());
      final currentMonth = DateTime.now().month;

      final imageLogo = pw.MemoryImage(
        (await rootBundle.load('assets/logo_PLC.jpg')).buffer.asUint8List(),
      );

      final warehousesFiltrados = warehouses.docs.where((doc) {
        final data = doc.data();
        final fecha = (data['fecha'] as Timestamp).toDate();
        return fecha.month == currentMonth;
      }).toList();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(imageLogo, height: 100, width: 70),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Warehouses creados en el mes de $monthName',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total de warehouses creados: ${warehousesFiltrados.length}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                // ignore: deprecated_member_use
                pw.Table.fromTextArray(
                  headers: ['WarehouseID', 'CargaID', 'Nombre del cliente', 'Dirección', 'Estatus', 'Fecha de creación', 'Modalidad', 'Peso', 'Paquetes'],
                  data: warehousesFiltrados.map((doc) {
                    final data = doc.data();
                    final fecha = (data['fecha'] as Timestamp).toDate();
                    return [
                      data['warehouse_id'] ?? 'Desconocido',
                      data['carga_id'] ?? 'Desconocido',
                      data['cliente_id'] ?? 'Desconocido',
                      data['direccion'] ?? 'Desconocido',
                      data['estatus_id'] ?? 'Desconocido',
                      DateFormat('dd/MM/yyyy').format(fecha),
                      data['modalidad'] ?? 'Desconocido',
                      data['peso_total']?.toString() ?? 'Desconocido',
                      data['piezas']?.toString() ?? 'Desconocido',
                    ];
                  }).toList(),
                ),
                pw.Spacer(),
                pw.Container(
                  color: PdfColors.blue,
                  height: 50,
                  child: pw.Center(
                    child: pw.Text(
                      'Premium Logistics Cargo',
                      style: const pw.TextStyle(color: PdfColors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(selectedIndex: 2, controller: _sidebarXController),
      body: Column(
        children: [
          AppBar(
            title:
                const Text('Warehouse', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange.shade700,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por warehouse_id, carga_id o cliente_id',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getWare(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error al obtener los almacenes'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No hay almacenes disponibles'));
                }

                final filteredDocs = snapshot.data!.docs.where((document) {
                  final data = document.data() as Map<String, dynamic>? ?? {};
                  final whId = document['warehouse_id']
                      .toString()
                      .toLowerCase();
                  final cargaId = data['carga_id']?.toString().toLowerCase() ?? '';
                  final clientId = data['cliente_id']?.toString().toLowerCase() ?? '';
                  final search = _searchTerm.toLowerCase();
                  return search.isEmpty ||
                      whId.contains(search) ||
                      cargaId.contains(search) ||
                      clientId.contains(search);
                }).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 600,
                        headingRowColor:
                            WidgetStateProperty.all(Colors.blue.shade100),
                        dataRowColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? Colors.blue.shade50
                                : Colors.white),
                        columns: const [
                          DataColumn2(
                              label: Text('WarehouseID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('CargaID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Nombre del cliente',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Dirección',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Estatus',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Fecha de creación',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Modalidad',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Peso',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Paquetes',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredDocs.map((DocumentSnapshot document) {
                          Map<String, dynamic>? data =
                              document.data() as Map<String, dynamic>?;
                          if (data == null) {
                            return const DataRow(cells: [
                              DataCell(Text('Error al cargar datos'))
                            ]);
                          }

                          return DataRow(
                            cells: [
                              DataCell(Text(document['warehouse_id'])),
                              DataCell(Text(data['carga_id']?.toString() ??
                                  'Desconocido')),
                              DataCell(FutureBuilder(
                                future:
                                    getClientFullName(data['cliente_id'] ?? ''),
                                builder: (context, snapshot) =>
                                    Text(snapshot.data ?? 'Cargando...'),
                              )),
                              DataCell(
                                  Text(data['direccion'] ?? 'Desconocido')),
                              DataCell(FutureBuilder(
                                future: getEstatusNameById(
                                    data['estatus_id'] ?? ''),
                                builder: (context, snapshot) =>
                                    Text(snapshot.data ?? 'Cargando...'),
                              )),
                              DataCell(Text(formatDate(data['fecha']))),
                              DataCell(FutureBuilder(
                                future: getModalidadNameById(
                                    data['modalidad'] ?? ''),
                                builder: (context, snapshot) =>
                                    Text(snapshot.data ?? 'Cargando...'),
                              )),
                              DataCell(Text(data['peso_total'].toString())),
                              DataCell(Text(data['piezas'].toString())),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: generatePdf,
        child: const Icon(Icons.picture_as_pdf),
      ),
    );
  }
}
