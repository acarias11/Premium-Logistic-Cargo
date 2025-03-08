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

class PaquetesPage extends StatefulWidget {
  const PaquetesPage({super.key});
  @override
  _PaquetesPageState createState() => _PaquetesPageState();
}

class _PaquetesPageState extends State<PaquetesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService firestoreService = FirestoreService();
  final ControladorPaquetes controladorPaquete = ControladorPaquetes();
  final SidebarXController _sidebarXController = SidebarXController(selectedIndex: 0);
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

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
      modalidades = snapshot.docs.map((doc) => doc['Nombre'].toString()).toList();
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
        title: const Text('Nuevo Paquete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: controladorPaquete.traking_numberController,
              decoration: const InputDecoration(labelText: 'Traking Number'),
            ),
            TextField(
              controller: controladorPaquete.warehouseIDController,
              decoration: const InputDecoration(labelText: 'Warehouse ID'),
            ),
            TextField(
              controller: controladorPaquete.direccionController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            TextField(
              controller: controladorPaquete.pesoController,
              decoration: const InputDecoration(labelText: 'Peso'),
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
                  child: Text(value),
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
                  child: Text(value),
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
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Validar que el peso sea un número mayor que 0
              double peso = double.tryParse(controladorPaquete.pesoController.text) ?? -1;
              if (peso <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El peso debe ser un número mayor que 0')),
                );
                return;
              }

              //LLAMAR A LA FUNCIÓN DE FIRESTORE PARA AGREGAR EL PAQUETE
              firestoreService.addPaquete(
                controladorPaquete.traking_numberController.text,
                controladorPaquete.warehouseIDController.text,
                controladorPaquete.direccionController.text,
                peso,
                tipoPaquete!,
                modalidadEnvio!,
                controladorPaquete.estatusIDController.text,
              );
              // Limpiar los controladores después de agregar el paquete
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
            child: const Text('Agregar'),
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

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    height: 50,
                    width: 50,
                    color: PdfColors.grey300,
                    child: pw.Center(child: pw.Text('Logo')),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text('PLC', style: const pw.TextStyle(fontSize: 20)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Durante el mes de $monthName, se llevó a cabo el registro y creación de paquetes dentro del sistema,' 
                'con un total de ${paquetes.size} paquetes generados en este período. \n' 
                'Este reporte detalla la cantidad de paquetes creados, permitiendo un mejor control y' 
                'seguimiento de la logística y gestión operativa. La información recopilada servirá para' 
                'evaluar el rendimiento y la eficiencia en la administración de paquetes, así como para '
                'identificar posibles mejoras en los procesos de almacenamiento y distribución.',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: ['ID', 'Warehouse ID', 'Peso'],
                data: paquetes.docs.map((doc) {
                  final data = doc.data();
                  String warehouseId = "Desconocido";
                  if (data['WarehouseID'] is DocumentReference) {
                    warehouseId = (data['WarehouseID'] as DocumentReference).id;
                  } else if (data['WarehouseID'] is String) {
                    warehouseId = data['WarehouseID'];
                  }
                  return [
                    doc.id,
                    warehouseId,
                    '${data['Peso']?.toString() ?? 'Sin peso'} kg',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //* Se agrega un campo de texto para buscar por paquete_id o warehouse_id
        title: const Text('Paquetes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por paquete_id o warehouse_id',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
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
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: generatePdf,
          ),
        ],
      ),
      drawer: Sidebar(selectedIndex: 3, controller: _sidebarXController),
      floatingActionButton: FloatingActionButton(
        onPressed: nuevoPaquete,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPaq(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al obtener los paquetes'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay paquetes disponibles'));
          }

          var filteredDocs = snapshot.data!.docs.where((DocumentSnapshot document) {
            Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;
            if (data == null) return false;

            String paqueteId = data['paquete_id']?.toString() ?? '';
            String warehouseId = data['WarehouseID']?.toString() ?? '';

            return paqueteId.contains(_searchText) || warehouseId.contains(_searchText);
          }).toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width, // Asegura que el DataTable2 tenga un ancho adecuado
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 600,
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Warehouse ID')),
                    DataColumn(label: Text('Peso')),
                  ],
                  rows: filteredDocs.map((DocumentSnapshot document) {
                    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

                    if (data == null) return const DataRow(cells: [DataCell(Text('Error al cargar datos'))]);

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
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
