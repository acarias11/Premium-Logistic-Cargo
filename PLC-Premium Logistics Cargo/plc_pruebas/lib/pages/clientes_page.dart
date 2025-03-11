import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:plc_pruebas/services/firestore.dart';
import 'package:plc_pruebas/controllers/controladores.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/date_symbol_data_local.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});
  @override
  _ClientesPageState createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService firestoreService = FirestoreService();
  final ControladorClientes controladorCliente = ControladorClientes();
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 4);
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(
        'es', null); // Inicializar la configuración regional
  }

  void nuevoCliente() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                  controller: controladorCliente.nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(
                  controller: controladorCliente.apellidoController,
                  decoration: const InputDecoration(labelText: 'Apellido')),
              TextField(
                  controller: controladorCliente.emailController,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                  controller: controladorCliente.numero_identidadController,
                  decoration:
                      const InputDecoration(labelText: 'Número de Identidad')),
              TextField(
                  controller: controladorCliente.telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono')),
              TextField(
                  controller: controladorCliente.direccionController,
                  decoration: const InputDecoration(labelText: 'Dirección')),
              TextField(
                  controller: controladorCliente.ciudadController,
                  decoration: const InputDecoration(labelText: 'Ciudad')),
              TextField(
                  controller: controladorCliente.departamentoController,
                  decoration: const InputDecoration(labelText: 'Departamento')),
              TextField(
                  decoration: const InputDecoration(labelText: 'País'),
                  enabled: false,
                  controller: TextEditingController(text: 'Honduras')),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (controladorCliente.nombreController.text.isEmpty ||
                  controladorCliente.apellidoController.text.isEmpty ||
                  controladorCliente.emailController.text.isEmpty ||
                  controladorCliente.numero_identidadController.text.isEmpty ||
                  controladorCliente.telefonoController.text.isEmpty ||
                  controladorCliente.direccionController.text.isEmpty ||
                  controladorCliente.ciudadController.text.isEmpty ||
                  controladorCliente.departamentoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Todos los campos son obligatorios')));
                return;
              }
              firestoreService.addCliente(
                controladorCliente.nombreController.text,
                controladorCliente.apellidoController.text,
                controladorCliente.numero_identidadController.text,
                controladorCliente.emailController.text,
                controladorCliente.telefonoController.text,
                controladorCliente.direccionController.text,
                controladorCliente.ciudadController.text,
                controladorCliente.departamentoController.text,
                'Honduras',
              );
              controladorCliente.nombreController.clear();
              controladorCliente.apellidoController.clear();
              controladorCliente.emailController.clear();
              controladorCliente.numero_identidadController.clear();
              controladorCliente.telefonoController.clear();
              controladorCliente.direccionController.clear();
              controladorCliente.ciudadController.clear();
              controladorCliente.departamentoController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> getClientes() {
    return _firestore.collection('Clientes').snapshots();
  }

  Future<void> generatePdf() async {
    try {
      final pdf = pw.Document();

      final clientes = await _firestore.collection('Clientes').get();

      final headers = [
        'Nombre',
        'Apellido',
        'Número de Identidad',
        'Email',
        'Teléfono',
        'Dirección',
        'Ciudad',
        'Departamento',
        'País'
      ];

      final data = clientes.docs.map((doc) {
        final data = doc.data();
        return [
          data['nombre'] ?? 'Sin Nombre',
          data['apellido'] ?? 'Sin Apellido',
          data['numero_identidad'] ?? 'Sin Número de Identidad',
          data['email'] ?? 'Sin Email',
          data['telefono'] ?? 'Sin Teléfono',
          data['direccion'] ?? 'Sin Dirección',
          data['ciudad'] ?? 'Sin Ciudad',
          data['departamento'] ?? 'Sin Departamento',
          data['pais'] ?? 'Honduras',
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return [
              pw.Text(
                "Reporte de clientes",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),  // Nombre
                  1: const pw.FixedColumnWidth(80),  // Apellido
                  2: const pw.FixedColumnWidth(80),  // Email
                  3: const pw.FixedColumnWidth(80),  // Número de Identidad
                  4: const pw.FixedColumnWidth(60),  // Teléfono
                  5: const pw.FixedColumnWidth(60),  // Dirección
                  6: const pw.FixedColumnWidth(60),  // Ciudad
                  7: const pw.FixedColumnWidth(40),  // Departamento
                  8: const pw.FixedColumnWidth(40),  // País
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
        name: 'Reporte_de_Clientes.pdf',
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
          'Clientes',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => nuevoCliente(),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Buscar por Número de Identidad',
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
                stream: getClientes(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text(
                      'Error al obtener los clientes',
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
                      'No hay clientes disponibles',
                      style: TextStyle(color: Colors.white),
                    ));
                  }
                  var filteredDocs =
                      snapshot.data!.docs.where((DocumentSnapshot document) {
                    Map<String, dynamic>? data =
                        document.data() as Map<String, dynamic>?;
                    if (data == null) return false;
                    String numeroIdentidad =
                        data['numero_identidad']?.toString() ?? '';
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
                            DataColumn2(label: Text('Nombre')),
                            DataColumn2(label: Text('Apellido')),
                            DataColumn2(label: Text('Número de Identidad')),
                            DataColumn2(label: Text('Email')),
                            DataColumn2(label: Text('Teléfono')),
                            DataColumn2(label: Text('Dirección')),
                            DataColumn2(label: Text('Ciudad')),
                            DataColumn2(label: Text('Departamento')),
                            DataColumn2(label: Text('País')),
                          ],
                          source: _ClientesDataSource(filteredDocs),
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

class _ClientesDataSource extends DataTableSource {
  final List<DocumentSnapshot> _docs;

  _ClientesDataSource(this._docs);

  @override
  DataRow getRow(int index) {
    final document = _docs[index];
    final data = document.data() as Map<String, dynamic>?;

    if (data == null) {
      return const DataRow(cells: [DataCell(Text('Error al cargar datos'))]);
    }

    return DataRow(cells: [
      DataCell(Text(data['nombre'] ?? 'Sin Nombre')),
      DataCell(Text(data['apellido'] ?? 'Sin Apellido')),
      DataCell(Text(data['numero_identidad'] ?? 'Sin Número de Identidad')),
      DataCell(Text(data['email'] ?? 'Sin Email')),
      DataCell(Text(data['telefono'] ?? 'Sin Teléfono')),
      DataCell(Text(data['direccion'] ?? 'Sin Dirección')),
      DataCell(Text(data['ciudad'] ?? 'Sin Ciudad')),
      DataCell(Text(data['departamento'] ?? 'Sin Departamento')),
      DataCell(Text(data['pais'] ?? 'Honduras')),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _docs.length;

  @override
  int get selectedRowCount => 0;
}