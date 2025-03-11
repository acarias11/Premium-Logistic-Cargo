import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:sidebarx/sidebarx.dart';
import '../services/firestore.dart';
import '../widgets/sidebar.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;

class CargasPage extends StatefulWidget {
  const CargasPage({super.key});
  @override
  _CargasPageState createState() => _CargasPageState();
}

class _CargasPageState extends State<CargasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService firestoreService = FirestoreService();
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 1);

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fechaInicialController = TextEditingController();
  final TextEditingController _fechaFinalController = TextEditingController();
  final TextEditingController _entregaInicialController = TextEditingController();
  final TextEditingController _entregaFinalController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _piezasController = TextEditingController();

  List<String> estatuses = [];
  List<String> modalidades = [];
  String? selectedEstatus;
  String? selectedModalidad;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadEstatuses();
    _loadModalidades();
    initializeDateFormatting(
        'es', null); // Inicializar la configuración regional
  }

  Future<void> _loadEstatuses() async {
    QuerySnapshot snapshot = await firestoreService.estatus.get();
    setState(() {
      estatuses = snapshot.docs.map((doc) => doc['Nombre'].toString()).toList();
      selectedEstatus = estatuses.isNotEmpty ? estatuses[0] : null;
    });
  }

  Future<void> _loadModalidades() async {
    QuerySnapshot snapshot = await firestoreService.modalidad.get();
    setState(() {
      modalidades =
          snapshot.docs.map((doc) => doc['Nombre'].toString()).toList();
      selectedModalidad = modalidades.isNotEmpty ? modalidades[0] : null;
    });
  }

  Stream<QuerySnapshot> getcar() {
    return firestoreService.getCargas();
  }

  Future<String> getDocumentName(DocumentReference ref) async {
    DocumentSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      return snapshot['Nombre'] ?? 'Desconocido';
    }
    return 'Desconocido';
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Desconocido';
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return DateFormat('dd/MM/yyyy').format(date);
    }
    if (timestamp is String) {
      DateTime? date = DateTime.tryParse(timestamp);
      if (date != null) {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    }
    return 'Desconocido';
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _addCarga() async {
    try {
      if (_fechaInicialController.text.isEmpty ||
          _fechaFinalController.text.isEmpty ||
          _entregaInicialController.text.isEmpty ||
          _entregaFinalController.text.isEmpty ||
          _pesoController.text.isEmpty ||
          _piezasController.text.isEmpty ||
          selectedEstatus == null ||
          selectedModalidad == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, complete todos los campos')),
        );
        return;
      }

      // Convertir fechas
      DateTime fechaInicial = DateFormat('dd/MM/yyyy').parse(_fechaInicialController.text);
      DateTime fechaFinal = DateFormat('dd/MM/yyyy').parse(_fechaFinalController.text);
      DateTime entregaInicial = DateFormat('dd/MM/yyyy').parse(_entregaInicialController.text);
      DateTime entregaFinal = DateFormat('dd/MM/yyyy').parse(_entregaFinalController.text);

      // Convertir peso y piezas
      double peso = double.parse(_pesoController.text);
      int piezas = int.parse(_piezasController.text);

      // Enviar nombres legibles directamente
      await firestoreService.addCarga(
        DateFormat('dd/MM/yyyy').format(entregaInicial),
        DateFormat('dd/MM/yyyy').format(entregaFinal),
        selectedEstatus!,        // Enviar 'Completado', 'En Transito', etc.
        DateFormat('dd/MM/yyyy').format(fechaInicial),
        DateFormat('dd/MM/yyyy').format(fechaFinal),
        selectedModalidad!,      // Enviar 'Aereo', 'Maritimo'
        peso,
        piezas,
      );

      // Limpiar los campos después de agregar la carga
      _fechaInicialController.clear();
      _fechaFinalController.clear();
      _entregaInicialController.clear();
      _entregaFinalController.clear();
      _pesoController.clear();
      _piezasController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carga añadida exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir carga: $e')),
      );
    }
  }


  Future<void> generatePdf() async {
    try {
      final pdf = pw.Document();

      final cargas = await _firestore.collection('Carga').get();

      final monthName = DateFormat.MMMM('es').format(DateTime.now());
      final currentMonth = DateTime.now().month;

      final imageLogo = pw.MemoryImage(
        (await rootBundle.load('assets/logo_PLC.jpg')).buffer.asUint8List(),
      );

      final cargasFiltradas = cargas.docs.where((doc) {
        final data = doc.data();
        final estatus = data['estatus_id'];
        final fechaEntrega = data['entrega_final'];
        DateTime fechaEntregaDate;
        if (fechaEntrega is Timestamp) {
          fechaEntregaDate = fechaEntrega.toDate();
        } else if (fechaEntrega is String) {
          try {
            fechaEntregaDate = DateFormat('dd/MM/yyyy').parse(fechaEntrega);
          } catch (e) {
            return false;
          }
        } else {
          return false;
        }
        // Filtra cargas cuyo estatus_id sea 'EST1' (Completado) y que pertenezcan al mes actual.
        return estatus == 'EST1' && fechaEntregaDate.month == DateTime.now().month;
      }).toList();


      final headers = [
        'ID',
        'Fecha en almacen',
        'Fecha de Entrega',
        'Estatus',
        'Modalidad',
        'Peso',
        'Piezas'
      ];

      final data = await Future.wait(cargasFiltradas.map((doc) async {
        final data = doc.data();
        final fechaInicial = data['entrega_inicial'];
        final fechaFinal = data['entrega_final'];
        DateTime fechaInicialDate;
        DateTime fechaFinalDate;
        if (fechaInicial is Timestamp) {
          fechaInicialDate = fechaInicial.toDate();
        } else if (fechaInicial is String) {
          try {
            fechaInicialDate = DateFormat('dd/MM/yyyy').parse(fechaInicial);
          } catch (e) {
            fechaInicialDate = DateTime.now();
          }
        } else {
          fechaInicialDate = DateTime.now();
        }
        if (fechaFinal is Timestamp) {
          fechaFinalDate = fechaFinal.toDate();
        } else if (fechaFinal is String) {
          try {
            fechaFinalDate = DateFormat('dd/MM/yyyy').parse(fechaFinal);
          } catch (e) {
            fechaFinalDate = DateTime.now();
          }
        } else {
          fechaFinalDate = DateTime.now();
        }
        return [
          doc.id,
          DateFormat('dd/MM/yyyy').format(fechaInicialDate),
          DateFormat('dd/MM/yyyy').format(fechaFinalDate),
          await firestoreService.getEstatusNameById(data['estatus_id'] ?? 'Desconocido'),
          await firestoreService.getModalidadNameById(data['modalidad'] ?? 'Desconocido'),
          '${data['peso']?.toString() ?? 'Sin peso'} kg',
          data['piezas']?.toString() ?? 'Sin piezas',
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
                'Cargas exitosas del mes de $monthName',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Total de cargas exitosas: ${cargasFiltradas.length}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),  // ID
                  1: const pw.FixedColumnWidth(80),  // Fecha en almacen
                  2: const pw.FixedColumnWidth(80),  // Fecha de Entrega
                  3: const pw.FixedColumnWidth(60),  // Estatus
                  4: const pw.FixedColumnWidth(60),  // Modalidad
                  5: const pw.FixedColumnWidth(60),  // Peso
                  6: const pw.FixedColumnWidth(60),  // Piezas
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(selectedIndex: 2, controller: _sidebarXController),
      appBar: AppBar(
        backgroundColor: Colors.orange.shade700,
        title: const Text(
          'Cargas',
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                      hintText: 'CargaID',
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
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Añadir Carga'),
                            content: SingleChildScrollView(
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _fechaInicialController,
                                    decoration: InputDecoration(
                                      labelText: 'Fecha Inicial',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () => _selectDate(
                                            context, _fechaInicialController),
                                      ),
                                    ),
                                  ),
                                  TextField(
                                    controller: _fechaFinalController,
                                    decoration: InputDecoration(
                                      labelText: 'Fecha Final',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () => _selectDate(
                                            context, _fechaFinalController),
                                      ),
                                    ),
                                  ),
                                  TextField(
                                    controller: _entregaInicialController,
                                    decoration: InputDecoration(
                                      labelText: 'Entrega Inicial',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () => _selectDate(
                                            context, _entregaInicialController),
                                      ),
                                    ),
                                  ),
                                  TextField(
                                    controller: _entregaFinalController,
                                    decoration: InputDecoration(
                                      labelText: 'Entrega Final',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () => _selectDate(
                                            context, _entregaFinalController),
                                      ),
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: selectedEstatus,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedEstatus = newValue;
                                      });
                                    },
                                    items: estatuses.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    hint: const Text('Seleccionar Estatus'),
                                  ),
                                  DropdownButton<String>(
                                    value: selectedModalidad,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedModalidad = newValue;
                                      });
                                    },
                                    items: modalidades.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    hint: const Text('Seleccionar Modalidad'),
                                  ),
                                  TextField(
                                    controller: _pesoController,
                                    decoration:
                                        const InputDecoration(labelText: 'Peso'),
                                    keyboardType: TextInputType.number,
                                  ),
                                  TextField(
                                    controller: _piezasController,
                                    decoration: const InputDecoration(
                                        labelText: 'Piezas'),
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
                              ElevatedButton(
                                onPressed: () {
                                  _addCarga();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Añadir'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Añadir Carga'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getcar(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error al obtener las cargas'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No hay cargas disponibles'));
                  }
                  var filteredDocs = snapshot.data!.docs.where((doc) {
                    var id = doc.id.toLowerCase();
                    var searchQuery = _searchController.text.toLowerCase();
                    return id.contains(searchQuery);
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
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Fecha en almacen')),
                            DataColumn(label: Text('Fecha de Entrega')),
                            DataColumn(label: Text('Estatus')),
                            DataColumn(label: Text('Modalidad')),
                            DataColumn(label: Text('Peso')),
                            DataColumn(label: Text('Piezas')),
                          ],
                          source: _CargasDataSource(context, filteredDocs, getDocumentName, formatDate, firestoreService),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: generatePdf,
        child: const Icon(Icons.picture_as_pdf),
      ),
    );
  }
}

class _CargasDataSource extends DataTableSource {
  final BuildContext context;
  final List<DocumentSnapshot> _docs;
  final Future<String> Function(DocumentReference) getDocumentName;
  final String Function(dynamic) formatDate;
  final FirestoreService firestoreService;

  _CargasDataSource(this.context, this._docs, this.getDocumentName, this.formatDate, this.firestoreService);

  @override
  DataRow? getRow(int index) {
    final document = _docs[index];
    final data = document.data() as Map<String, dynamic>?;

    if (data == null) {
      return const DataRow(cells: [DataCell(Text('Error al cargar datos'))]);
    }

    String estatusID = data['estatus_id'] ?? 'Desconocido';
    String modalidadID = data['modalidad'] ?? 'Desconocido';

    String fechaInicial = 'Desconocido';
    if (data['fecha_inicial'] is Timestamp) {
      fechaInicial = formatDate(data['fecha_inicial']);
    } else if (data['fecha_inicial'] is String) {
      fechaInicial = data['fecha_inicial'];
    }

    String fechaFinal = 'Desconocido';
    if (data['fecha_final'] is Timestamp) {
      fechaFinal = formatDate(data['fecha_final']);
    } else if (data['fecha_final'] is String) {
      fechaFinal = data['fecha_final'];
    }

    return DataRow(cells: [
      DataCell(
        InkWell(
          child: Text(
            document.id,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/cargoPage', arguments: document.id);
          },
        ),
      ),
      DataCell(Text(fechaInicial)),
      DataCell(Text(fechaFinal)),
      DataCell(FutureBuilder<String>(
        future: firestoreService.getEstatusNameById(estatusID),
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
      DataCell(FutureBuilder<String>(
        future: firestoreService.getModalidadNameById(modalidadID),
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
      DataCell(Text(data['peso']?.toString() ?? 'Desconocido')),
      DataCell(Text(data['piezas']?.toString() ?? 'Desconocido')),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _docs.length;

  @override
  int get selectedRowCount => 0;
}

