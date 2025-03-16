import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plc_pruebas/services/firestore.dart';
import 'package:plc_pruebas/controllers/controladores.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PaquetesPage extends StatefulWidget {
  const PaquetesPage({super.key});

  @override
  _PaquetesPageState createState() => _PaquetesPageState();
}

class _PaquetesPageState extends State<PaquetesPage>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService firestoreService = FirestoreService();
  final ControladorPaquetes controladorPaquete = ControladorPaquetes();
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 3);
  final TextEditingController _searchController = TextEditingController();

  // GlobalKey para acceder al estado interno de la tabla
  final GlobalKey<_PaquetesTableState> paquetesTableKey =
      GlobalKey<_PaquetesTableState>();

  String _searchTerm = '';
  // Lista global con los documentos filtrados que se muestran actualmente
  List<DocumentSnapshot> _currentFilteredDocs = [];
  String _selectedTipo = 'Caja'; // Valor por defecto

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
  }

  // Stream para obtener los paquetes desde Firestore
  Stream<QuerySnapshot> getPaq() {
    return _firestore.collection('Paquetes').snapshots();
  }

  // PDF que contiene únicamente los datos mostrados (página actual)
  Future<void> generatePdf() async {
    try {
      final pdf = pw.Document();
      final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
      final monthName = DateFormat.MMMM('es').format(DateTime.now());
      // Obtener el índice de la primera fila de la página actual y el número de filas por página
      final int currentPage = paquetesTableKey.currentState?.currentPage ?? 0;
      final int rowsPerPage = paquetesTableKey.currentState?.currentRowsPerPage ?? 10;
      final int start = currentPage;
      final int end = (currentPage + rowsPerPage) > _currentFilteredDocs.length
          ? _currentFilteredDocs.length
          : (currentPage + rowsPerPage);
      final List<DocumentSnapshot> currentPageDocs =
          _currentFilteredDocs.sublist(start, end);

      // Cargar el logo desde los assets
      final imageLogo = pw.MemoryImage(
        (await rootBundle.load('assets/logo_PLC.jpg')).buffer.asUint8List(),
      );

      // Encabezados para el PDF
      final headers = ['ID', 'Warehouse ID', 'Peso'];

      // Construir los datos de la tabla PDF a partir de los documentos mostrados
      final data = currentPageDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return ['Error', 'Error', 'Error'];
        String warehouseId = "Desconocido";
        if (data['WarehouseID'] is DocumentReference) {
          warehouseId = (data['WarehouseID'] as DocumentReference).id;
        } else if (data['WarehouseID'] is String) {
          warehouseId = data['WarehouseID'];
        }
        return [
          data['paquete_id']?.toString() ?? 'Sin ID',
          warehouseId,
          '${data['Peso']?.toString() ?? 'Sin peso'} kg'
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3,
          margin: const pw.EdgeInsets.all(16),
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
                ),
                // Número de página en el formato "1/5"
                pw.Text(
                  '$currentPage/$totalPages',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.white),
                ),
              ],
            ),
          );
        },
          build: (context) {
            return [
              pw.Text(
              'Durante el mes de $monthName, se llevó a cabo el registro y la creación de paquetes dentro del sistema,'
              'con un total de ${currentPageDocs.length} paquetes generados en este período. \n'
              'Este reporte detalla la cantidad de paquetes creados, permitiendo un mejor control y'
              'seguimiento de la logística y gestión operativa. La información recopilada servirá para'
              'evaluar el rendimiento y la eficiencia en la administración de paquetes, así como para '
              'identificar posibles mejoras en los procesos de almacenamiento y distribución.',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
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
        name: 'Reporte_de_Paquetes.pdf',
      );
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  // Función para agregar un nuevo paquete (copia la lógica que utilizas)
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
                labelText: 'Tracking Number',
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
            DropdownButtonFormField<String>(
              value: _selectedTipo,
              items: ['Caja', 'Bulto', 'Sobre'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedTipo = newValue!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Tipo de Paquete',
                labelStyle: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () async {
              double peso = double.tryParse(
                      controladorPaquete.pesoController.text) ?? -1;
              if (peso <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('El peso debe ser mayor que 0')));
                return;
              }
              if (controladorPaquete.traking_numberController.text.isEmpty ||
                  controladorPaquete.warehouseIDController.text.isEmpty ||
                  controladorPaquete.direccionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Complete todos los campos')));
                return;
              }
              try {
                await firestoreService.addPaquete(
                  controladorPaquete.traking_numberController.text,
                  controladorPaquete.warehouseIDController.text,
                  controladorPaquete.direccionController.text,
                  peso,
                  _selectedTipo, // Utiliza el valor seleccionado
                );
                controladorPaquete.traking_numberController.clear();
                controladorPaquete.warehouseIDController.clear();
                controladorPaquete.direccionController.clear();
                controladorPaquete.pesoController.clear();
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al agregar paquete: $e')));
              }
            },
            child: const Text('Agregar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario por AutomaticKeepAliveClientMixin
    return Scaffold(
      drawer: Sidebar(selectedIndex: 3, controller: _sidebarXController),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text('Paquetes', style: TextStyle(color: Colors.white)),
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
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Error al obtener los paquetes',
                      style: TextStyle(color: Colors.white)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No hay paquetes disponibles',
                      style: TextStyle(color: Colors.white)));
            }
            // Filtrar documentos según el término de búsqueda
            var filteredDocs = snapshot.data!.docs.where((document) {
              Map<String, dynamic>? data =
                  document.data() as Map<String, dynamic>?;
              if (data == null) return false;
              String paqueteId =
                  data['paquete_id']?.toString().toLowerCase() ?? '';
              String warehouseId =
                  data['WarehouseID']?.toString().toLowerCase() ?? '';
              return _searchTerm.isEmpty ||
                  paqueteId.contains(_searchTerm) ||
                  warehouseId.contains(_searchTerm);
            }).toList();

            // Actualizamos la lista global de documentos filtrados
            _currentFilteredDocs = filteredDocs;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: PaquetesTable(
                    key: paquetesTableKey,
                    docs: filteredDocs,
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

// Widget separado para la tabla de Paquetes
class PaquetesTable extends StatefulWidget {
  final List<DocumentSnapshot> docs;
  const PaquetesTable({super.key, required this.docs});

  @override
  _PaquetesTableState createState() => _PaquetesTableState();
}

class _PaquetesTableState extends State<PaquetesTable> {
  int _currentPage = 0;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  int get currentPage => _currentPage;
  int get currentRowsPerPage => _rowsPerPage;

  @override
  Widget build(BuildContext context) {
    return PaginatedDataTable2(
      key: const PageStorageKey('paquetesTable'),
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
      source: _PaquetesDataSource(widget.docs),
      rowsPerPage: _rowsPerPage,
      availableRowsPerPage: const [10, 20, 50],
      onRowsPerPageChanged: (value) {
        setState(() {
          _rowsPerPage = value!;
        });
      },
      onPageChanged: (firstRowIndex) {
        setState(() {
          _currentPage = firstRowIndex;
        });
      },
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
      return const DataRow(
          cells: [DataCell(Text('Error al cargar datos'))]);
    }
    String warehouseId = "Desconocido";
    if (data['WarehouseID'] is DocumentReference) {
      warehouseId =
          (data['WarehouseID'] as DocumentReference).id;
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