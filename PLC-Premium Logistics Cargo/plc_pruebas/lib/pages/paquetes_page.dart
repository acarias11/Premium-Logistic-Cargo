import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:plc_pruebas/services/firestore.dart';
import 'package:plc_pruebas/controllers/controladores.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;

class PaquetesPage extends StatefulWidget {
  const PaquetesPage({super.key});
  @override
  _PaquetesPageState createState() => _PaquetesPageState();
}

class _PaquetesPageState extends State<PaquetesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService firestoreService = FirestoreService();
  final ControladorPaquetes controladorPaquete = ControladorPaquetes();
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 3);
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
 int _rowsPerPage = 10;

  // Variables para modalidad de envío y tipo de paquete
  String? modalidadEnvio;
  String? tipoPaquete;
  List<String> modalidades = [];
  List<String> tipos = [];

  @override
  void initState() {
    super.initState();
    _loadModalidades();
    _loadTipos();
    initializeDateFormatting('es', null);
  }

  Future<void> _loadModalidades() async {
    QuerySnapshot snapshot = await firestoreService.modalidad.get();
    setState(() {
      modalidades =
          snapshot.docs.map((doc) => doc['Nombre'].toString()).toList();
      modalidadEnvio = modalidades.isNotEmpty ? modalidades[0] : null;
    });
  }

  Future<void> _loadTipos() async {
    QuerySnapshot snapshot = await firestoreService.tipo.get();
    setState(() {
      tipos = snapshot.docs.map((doc) => doc['Nombre'].toString()).toList();
      tipoPaquete = tipos.isNotEmpty ? tipos[0] : null;
    });
  }

  //box para agregar un nuevo paquete
  void nuevoPaquete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Nuevo Paquete', style: TextStyle(color: Colors.blue)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: controladorPaquete.traking_numberController,
              decoration: const InputDecoration(
                labelText: 'Traking Number',
                labelStyle: TextStyle(color: Colors.orange),
              ),
            ),
            TextField(
              controller: controladorPaquete.warehouseIDController,
              decoration: const InputDecoration(
                labelText: 'Warehouse ID',
                labelStyle: TextStyle(color: Colors.orange),
              ),
            ),
            TextField(
              controller: controladorPaquete.direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                labelStyle: TextStyle(color: Colors.orange),
              ),
            ),
            TextField(
              controller: controladorPaquete.pesoController,
              decoration: const InputDecoration(
                labelText: 'Peso',
                labelStyle: TextStyle(color: Colors.orange),
              ),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: tipoPaquete,
              onChanged: (String? newValue) {
                setState(() {
                  tipoPaquete = newValue!;
                });
              },
              items: tipos.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child:
                      Text(value, style: const TextStyle(color: Colors.blue)),
                );
              }).toList(),
            ),
            DropdownButton<String>(
              value: modalidadEnvio,
              onChanged: (String? newValue) {
                setState(() {
                  modalidadEnvio = newValue!;
                });
              },
              items: modalidades.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child:
                      Text(value, style: const TextStyle(color: Colors.blue)),
                );
              }).toList(),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () {
              double peso =
                  double.tryParse(controladorPaquete.pesoController.text) ?? -1;
              if (peso <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('El peso debe ser un número mayor que 0')),
                );
                return;
              }
              firestoreService.addPaquete(
                controladorPaquete.traking_numberController.text,
                controladorPaquete.warehouseIDController.text,
                controladorPaquete.direccionController.text,
                peso,
                tipoPaquete!,
                modalidadEnvio!,
                controladorPaquete.estatusIDController.text,
              );
              controladorPaquete.traking_numberController.clear();
              controladorPaquete.warehouseIDController.clear();
              controladorPaquete.direccionController.clear();
              controladorPaquete.pesoController.clear();
              setState(() {
                modalidadEnvio = modalidades.isNotEmpty ? modalidades[0] : null;
                tipoPaquete = tipos.isNotEmpty ? tipos[0] : null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Agregar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> getPaq() {
    return _firestore.collection('Paquetes').snapshots();
  }

  Future<void> generatePdf() async {
    final pdf = pw.Document();

    final paquetes = await _firestore.collection('Paquetes').get();

    final monthName = DateFormat.MMMM('es').format(DateTime.now());
    final currentMonth = DateTime.now().month;

    // Cargar la imagen desde los assets
    final imageLogo = pw.MemoryImage(
      (await rootBundle.load('assets/logo_PLC.jpg')).buffer.asUint8List(),
    );

    final paquetesFiltrados = paquetes.docs.where((doc) {
      final data = doc.data();
      final fecha = (data['Fecha'] as Timestamp).toDate();
      return fecha.month == currentMonth;
    }).toList();

    final headers = ['ID', 'Warehouse ID', 'Peso', 'Fecha'];

    final data = paquetesFiltrados.map((doc) {
      final data = doc.data();
      String warehouseId = "Desconocido";
      if (data['WarehouseID'] is DocumentReference) {
        warehouseId = (data['WarehouseID'] as DocumentReference).id;
      } else if (data['WarehouseID'] is String) {
        warehouseId = data['WarehouseID'];
      }
      final fecha = (data['Fecha'] as Timestamp).toDate();
      final fechaFormateada = DateFormat('dd/MM/yyyy').format(fecha);
      return [
        data['paquete_id']?.toString() ?? 'Sin ID',
        warehouseId,
        '${data['Peso']?.toString() ?? 'Sin peso'} kg',
        fechaFormateada,
      ];
    }).toList();

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
              'Durante el mes de $monthName, se llevó a cabo el registro y creación de paquetes dentro del sistema,'
              'con un total de ${paquetesFiltrados.length} paquetes generados en este período. \n'
              'Este reporte detalla la cantidad de paquetes creados, permitiendo un mejor control y'
              'seguimiento de la logística y gestión operativa. La información recopilada servirá para'
              'evaluar el rendimiento y la eficiencia en la administración de paquetes, así como para '
              'identificar posibles mejoras en los procesos de almacenamiento y distribución.',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              columnWidths: {
                0: const pw.FixedColumnWidth(60),  // ID
                1: const pw.FixedColumnWidth(80),  // Warehouse ID
                2: const pw.FixedColumnWidth(60),  // Peso
                3: const pw.FixedColumnWidth(60),  // Fecha
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(selectedIndex: 3, controller: _sidebarXController),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text(
          'Paquetes',
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
                hintText: 'Buscar por paquete_id o warehouse_id',
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
                  _searchText = value.toUpperCase();
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
        onPressed: nuevoPaquete,
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add, color: Colors.white),
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
          stream: getPaq(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text(
                'Error al obtener los paquetes',
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
                'No hay paquetes disponibles',
                style: TextStyle(color: Colors.white),
              ));
            }

            var filteredDocs =
                snapshot.data!.docs.where((DocumentSnapshot document) {
              Map<String, dynamic>? data =
                  document.data() as Map<String, dynamic>?;
              if (data == null) return false;

              String paqueteId = data['paquete_id']?.toString() ?? '';
              String warehouseId = data['WarehouseID']?.toString() ?? '';

              return paqueteId.contains(_searchText) ||
                  warehouseId.contains(_searchText);
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
                      DataColumn(label: Text('Warehouse ID')),
                      DataColumn(label: Text('Peso')),
                    ],
                    source: _PaquetesDataSource(filteredDocs),
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

class _PaquetesDataSource extends DataTableSource {
  final List<DocumentSnapshot> _docs;

  _PaquetesDataSource(this._docs);

  @override
  DataRow getRow(int index) {
    final document = _docs[index];
    final data = document.data() as Map<String, dynamic>?;

    if (data == null) {
      return const DataRow(cells: [DataCell(Text('Error al cargar datos'))]);
    }

    String warehouseId = "Desconocido";
    if (data['WarehouseID'] is DocumentReference) {
      warehouseId = (data['WarehouseID'] as DocumentReference).id;
    } else if (data['WarehouseID'] is String) {
      warehouseId = data['WarehouseID'];
    }

    return DataRow(cells: [
      DataCell(Text(data['paquete_id']?.toString() ?? 'Sin ID')),
      DataCell(Text(warehouseId)),
      DataCell(Text('${data['Peso']?.toString() ?? 'Sin peso'} kg')),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _docs.length;

  @override
  int get selectedRowCount => 0;
}
