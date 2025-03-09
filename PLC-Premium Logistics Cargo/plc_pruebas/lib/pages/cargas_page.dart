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
      SidebarXController(selectedIndex: 0);

  TextEditingController _searchController = TextEditingController();
  TextEditingController _fechaInicialController = TextEditingController();
  TextEditingController _fechaFinalController = TextEditingController();
  TextEditingController _entregaInicialController = TextEditingController();
  TextEditingController _entregaFinalController = TextEditingController();
  TextEditingController _pesoController = TextEditingController();
  TextEditingController _piezasController = TextEditingController();

  List<String> estatuses = [];
  List<String> modalidades = [];
  String? selectedEstatus;
  String? selectedModalidad;

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
    DateTime fechaInicial =
        DateFormat('dd/MM/yyyy').parse(_fechaInicialController.text);
    DateTime fechaFinal =
        DateFormat('dd/MM/yyyy').parse(_fechaFinalController.text);
    DateTime entregaInicial =
        DateFormat('dd/MM/yyyy').parse(_entregaInicialController.text);
    DateTime entregaFinal =
        DateFormat('dd/MM/yyyy').parse(_entregaFinalController.text);
    String estatusID = selectedEstatus!;
    String modalidad = selectedModalidad!;
    double peso = double.parse(_pesoController.text);
    int piezas = int.parse(_piezasController.text);

    await firestoreService.addCarga(
      DateFormat('dd/MM/yyyy').format(entregaInicial),
      DateFormat('dd/MM/yyyy').format(entregaFinal),
      estatusID,
      DateFormat('dd/MM/yyyy').format(fechaInicial),
      DateFormat('dd/MM/yyyy').format(fechaFinal),
      modalidad,
      peso,
      piezas,
    );

    // Clear the text fields after adding the carga
    _fechaInicialController.clear();
    _fechaFinalController.clear();
    _entregaInicialController.clear();
    _entregaFinalController.clear();
    _pesoController.clear();
    _piezasController.clear();
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
        return estatus == 'Completado' &&
            fechaEntregaDate.month == currentMonth;
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
                  'Cargas exitosas del mes de $monthName',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total de cargas exitosas: ${cargasFiltradas.length}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                // ignore: deprecated_member_use
                pw.Table.fromTextArray(
                  headers: [
                    'ID',
                    'Fecha en almacen',
                    'Fecha de Entrega',
                    'Estatus',
                    'Modalidad',
                    'Peso',
                    'Piezas'
                  ],
                  data: cargasFiltradas.map((doc) {
                    final data = doc.data();
                    final fechaInicial = data['entrega_inicial'];
                    final fechaFinal = data['entrega_final'];
                    DateTime fechaInicialDate;
                    DateTime fechaFinalDate;
                    if (fechaInicial is Timestamp) {
                      fechaInicialDate = fechaInicial.toDate();
                    } else if (fechaInicial is String) {
                      try {
                        fechaInicialDate =
                            DateFormat('dd/MM/yyyy').parse(fechaInicial);
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
                        fechaFinalDate =
                            DateFormat('dd/MM/yyyy').parse(fechaFinal);
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
                      data['estatus_id'] ?? 'Desconocido',
                      data['modalidad'] ?? 'Desconocido',
                      '${data['peso']?.toString() ?? 'Sin peso'} kg',
                      data['piezas']?.toString() ?? 'Sin piezas',
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
      drawer: Sidebar(selectedIndex: 1, controller: _sidebarXController),
      body: Column(
        children: [
          AppBar(
            title: const Text('Cargas', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange.shade700,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por ID',
                      suffixIcon: Icon(Icons.search),
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
                                  items: estatuses
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
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
                                  items: modalidades
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
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
                              label: Text('ID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Fecha en almacen',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Fecha de Entrega',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Estatus',
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
                              label: Text('Piezas',
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

                          Future<String> estatusFuture =
                              data['estatus_id'] is DocumentReference
                                  ? getDocumentName(
                                      data['estatus_id'] as DocumentReference)
                                  : Future.value(
                                      data['estatus_id'] ?? 'Desconocido');

                          Future<String> modalidadFuture =
                              data['modalidad'] is DocumentReference
                                  ? getDocumentName(
                                      data['modalidad'] as DocumentReference)
                                  : Future.value(
                                      data['modalidad'] ?? 'Desconocido');

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
                                  Navigator.pushNamed(context, '/cargoPage',
                                      arguments: document.id);
                                },
                              ),
                            ),
                            DataCell(Text(formatDate(data['fecha_inicial']))),
                            DataCell(Text(formatDate(data['fecha_final']))),
                            DataCell(FutureBuilder<String>(
                              future: estatusFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text('Cargando...');
                                }
                                return Text(snapshot.data ?? 'Desconocido');
                              },
                            )),
                            DataCell(FutureBuilder<String>(
                              future: modalidadFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text('Cargando...');
                                }
                                return Text(snapshot.data ?? 'Desconocido');
                              },
                            )),
                            DataCell(Text(
                                data['peso']?.toString() ?? 'Desconocido')),
                            DataCell(Text(
                                data['piezas']?.toString() ?? 'Desconocido')),
                          ]);
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
