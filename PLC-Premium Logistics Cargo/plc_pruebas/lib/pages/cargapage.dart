import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:plc_pruebas/services/firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class CargoPage extends StatefulWidget {
  final String cargaId;

  const CargoPage({super.key, required this.cargaId});

  @override
  _CargoPageState createState() => _CargoPageState();
}

Future<String> getClientFullNameById(String clientId, FirestoreService firestoreService) async {
  DocumentSnapshot clientDoc = await firestoreService.getClientById(clientId);
  if (clientDoc.exists) {
    String nombre = clientDoc['nombre'] ?? 'Desconocido';
    String apellido = clientDoc['apellido'] ?? '';
    return '$nombre $apellido';
  } else {
    return 'Desconocido';
  }
}

class _CargoPageState extends State<CargoPage> {
  final FirestoreService firestoreService = FirestoreService();

  Stream<QuerySnapshot> getWarehousesByCargoId() {
    return firestoreService.getWarehousesCarga(widget.cargaId);
  }

  List<DropdownMenuItem<String>> estatusItems = [];
  List<DropdownMenuItem<String>> modalidadItems = [];
  List<DropdownMenuItem<String>> clientItems = [];
  String? selectedEstatus;
  String? selectedModalidad;
  String? selectedClientId;
  int _rowsPerPage = 10;

  Future<void> _loadClientes() async {
    QuerySnapshot snapshot = await firestoreService.getClientes('').first;
    setState(() {
      clientItems = snapshot.docs.map((DocumentSnapshot document) {
        String nombre = document['nombre'] ?? 'Desconocido';
        String apellido = document['apellido'] ?? '';
        String numeroIdentidad = document['numero_identidad'] ?? '';
        return DropdownMenuItem<String>(
          value: document.id,
          child: Text('$nombre $apellido ($numeroIdentidad)'),
        );
      }).toList();
      selectedClientId = clientItems.isNotEmpty ? clientItems[0].value : null;
    });
  }

  Future<void> _loadEstatus() async {
    QuerySnapshot snapshot = await firestoreService.getEstatus().first;
    setState(() {
      estatusItems = snapshot.docs.map((DocumentSnapshot document) {
        return DropdownMenuItem<String>(
          value: document.id,
          child: Text(document['Nombre']),
        );
      }).toList();
      selectedEstatus = estatusItems.isNotEmpty ? estatusItems[0].value : null;
    });
  }

  Future<void> _loadModalidades() async {
    QuerySnapshot snapshot = await firestoreService.getModalidades().first;
    setState(() {
      modalidadItems = snapshot.docs.map((DocumentSnapshot document) {
        return DropdownMenuItem<String>(
          value: document.id,
          child: Text(document['Nombre']),
        );
      }).toList();
      selectedModalidad =
          modalidadItems.isNotEmpty ? modalidadItems[0].value : null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadClientes();
    _loadEstatus();
    _loadModalidades();
  }

  Future<void> createWarehouse(BuildContext context) async {
    TextEditingController direccionController = TextEditingController();
    TextEditingController pesoController = TextEditingController();
    TextEditingController piezasController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Crear Warehouse'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Cliente'),
                      items: clientItems,
                      value: selectedClientId,
                      onChanged: (newValue) {
                        setState(() {
                          selectedClientId = newValue;
                        });
                      },
                    ),
                    TextField(
                      controller: direccionController,
                      decoration: const InputDecoration(labelText: 'Direccion'),
                    ),
                    TextField(
                      controller: pesoController,
                      decoration: const InputDecoration(labelText: 'Peso'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: piezasController,
                      decoration: const InputDecoration(labelText: 'Paquetes'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedClientId != null) {
                      await firestoreService.addWarehouse(
                        widget.cargaId,
                        selectedClientId!,
                        direccionController.text,
                        double.tryParse(pesoController.text) ?? 0,
                        int.tryParse(piezasController.text) ?? 0,
                      );
                      setState(() {
                        selectedClientId = null;
                        piezasController.clear();
                        pesoController.clear();
                        direccionController.clear();
                      });
                      Navigator.of(context).pop();
                    } else {
                      // Show error message if client is not selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Por favor seleccione un Cliente')),
                      );
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> generatePdf() async {
    try {
      final pdf = pw.Document();

      final warehouses = await firestoreService.getWarehousesCarga(widget.cargaId).first;

      final imageLogo = pw.MemoryImage(
        (await rootBundle.load('assets/logo_PLC.jpg')).buffer.asUint8List(),
      );

      final headers = [
        'WarehouseID',
        'Nombre del cliente',
        'Direccion',
        'Estatus',
        'Fecha de creacion',
        'Modalidad',
        'Peso',
        'Paquetes'
      ];

      final data = await Future.wait(warehouses.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        final fecha = (data['fecha'] as Timestamp).toDate();
        return [
          data['warehouse_id'] ?? 'Desconocido',
          await getClientFullNameById(data['cliente_id'] ?? '', firestoreService) ?? 'Desconocido',
          data['direccion'] ?? 'Desconocido',
          await firestoreService.getEstatusNameById(data['estatus_id'] ?? ''),
          DateFormat('dd/MM/yyyy').format(fecha),
          await firestoreService.getModalidadNameById(data['modalidad'] ?? ''),
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
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Image(imageLogo, height: 100, width: 70),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Reporte de Warehouses',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),  // WarehouseID
                  1: const pw.FixedColumnWidth(80),  // Nombre del cliente
                  2: const pw.FixedColumnWidth(80),  // Direccion
                  3: const pw.FixedColumnWidth(60),  // Estatus
                  4: const pw.FixedColumnWidth(60),  // Fecha de creacion
                  5: const pw.FixedColumnWidth(60),  // Modalidad
                  6: const pw.FixedColumnWidth(40),  // Peso
                  7: const pw.FixedColumnWidth(40),  // Paquetes
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
            ];
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

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Desconocido';
    return DateFormat('dd/MM/yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text(
          'Cargo Warehouses',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => createWarehouse(context),
          ),
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
          stream: getWarehousesByCargoId(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Error al obtener los almacenes',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No hay almacenes disponibles',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

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
                      DataColumn(label: Text('Nombre del cliente')),
                      DataColumn(label: Text('Direccion')),
                      DataColumn(label: Text('Estatus')),
                      DataColumn(label: Text('Fecha de creacion')),
                      DataColumn(label: Text('Modalidad')),
                      DataColumn(label: Text('Peso')),
                      DataColumn(label: Text('Paquetes')),
                    ],
                    source: _WarehousesDataSource(snapshot.data!.docs, (clientId) => getClientFullNameById(clientId, firestoreService), firestoreService.getEstatusNameById, firestoreService.getModalidadNameById, formatDate),
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
    );
  }
}

class _WarehousesDataSource extends DataTableSource {
  final List<DocumentSnapshot> _docs;
  final Future<String> Function(String) getClientFullNameById;
  final Future<String> Function(String) getEstatusNameById;
  final Future<String> Function(String) getModalidadNameById;
  final String Function(Timestamp?) formatDate;

  _WarehousesDataSource(this._docs, this.getClientFullNameById, this.getEstatusNameById, this.getModalidadNameById, this.formatDate);

  @override
  DataRow getRow(int index) {
    final document = _docs[index];
    final data = document.data() as Map<String, dynamic>?;

    if (data == null) {
      return const DataRow(cells: [DataCell(Text('Error al cargar datos'))]);
    }

    return DataRow(cells: [
      DataCell(Text(data['warehouse_id']?.toString() ?? '')),
      DataCell(FutureBuilder<String>(
        future: getClientFullNameById(data['cliente_id'] ?? ''),
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
            print('Error: ${snapshot.error}');
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
            print('Error: ${snapshot.error}');
            return const Text('Error');
          }
          return Text(snapshot.data ?? 'Desconocido');
        },
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