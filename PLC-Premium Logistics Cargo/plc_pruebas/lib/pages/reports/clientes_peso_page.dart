import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:data_table_2/data_table_2.dart';

class ClientesPesoPage extends StatefulWidget {
  const ClientesPesoPage({super.key});

  @override
  _ClientesPesoPageState createState() => _ClientesPesoPageState();
}

class _ClientesPesoPageState extends State<ClientesPesoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  Future<List<Map<String, dynamic>>> fetchClientesPeso() async {
    try {
      QuerySnapshot warehousesSnapshot = await _firestore.collection('Warehouse').get();
      Map<String, Map<String, dynamic>> clientesData = {};

      for (var doc in warehousesSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String clienteId = data['cliente_id'] ?? 'Desconocido';
          double peso = data['peso_total'] ?? 0.0;

          if (peso == 0.0) continue;

          if (!clientesData.containsKey(clienteId)) {
            clientesData[clienteId] = {
              'peso_total': 0.0,
              'total_warehouses': 0,
            };
          }

          clientesData[clienteId]!['peso_total'] += peso;
          clientesData[clienteId]!['total_warehouses'] += 1;
        } catch (e) {
          print('Error al procesar warehouse: $e');
        }
      }

      List<Map<String, dynamic>> clientesPeso = [];
      for (var clienteId in clientesData.keys) {
        try {
          DocumentSnapshot clienteSnapshot = await _firestore.collection('Clientes').doc(clienteId).get();
          String clienteNombre = clienteSnapshot.exists ? clienteSnapshot['nombre'] : 'Desconocido';
          String clienteTelefono = clienteSnapshot.exists ? clienteSnapshot['telefono'] : 'Desconocido';

          clientesPeso.add({
            'nombre': clienteNombre,
            'telefono': clienteTelefono,
            'cliente_id': clienteId,
            'peso_total': clientesData[clienteId]!['peso_total'],
            'total_warehouses': clientesData[clienteId]!['total_warehouses'],
          });
        } catch (e) {
          print('Error al obtener datos del cliente: $e');
        }
      }

      clientesPeso.sort((a, b) => b['peso_total'].compareTo(a['peso_total']));
      return clientesPeso;
    } catch (e) {
      print('Error al obtener los datos de los clientes: $e');
      return [];
    }
  }

  Future<void> generatePdf() async {
    try {
      final pdf = pw.Document();
      final clientesPeso = await fetchClientesPeso();

      final headers = [
        'Nombre del cliente',
        'Número',
        'Peso total',
        'Total de warehouses'
      ];

      final data = clientesPeso.map((cliente) {
        return [
          cliente['nombre'],
          cliente['telefono'],
          cliente['peso_total'].toString(),
          cliente['total_warehouses'].toString(),
        ];
      }).toList();

      final ByteData bytes = await rootBundle.load('assets/Logo_PLC.jpg');
      final Uint8List logo = bytes.buffer.asUint8List();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Clientes con más peso en sus warehouses",
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Image(pw.MemoryImage(logo), width: 100, height: 100),
                ],
              ),
              pw.SizedBox(height: 10),
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                border: pw.TableBorder.all(color: PdfColors.grey),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Clientes_Peso.pdf',
      );
    } catch (e) {
      print('Error al generar el PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes con más peso en sus warehouses'),
        backgroundColor: Colors.blue.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: generatePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchClientesPeso(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay datos disponibles'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width,
                    ),
                    child: PaginatedDataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 600,
                      columns: const [
                        DataColumn2(label: Text('Nombre del cliente')),
                        DataColumn2(label: Text('Número')),
                        DataColumn2(label: Text('Peso total')),
                        DataColumn2(label: Text('Total de warehouses')),
                      ],
                      source: ClientesPesoDataSource(snapshot.data!),
                      rowsPerPage: _rowsPerPage,
                      availableRowsPerPage: const [10, 20, 50],
                      onRowsPerPageChanged: (value) {
                        setState(() {
                          _rowsPerPage = value!;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ClientesPesoDataSource extends DataTableSource {
  final List<Map<String, dynamic>> data;

  ClientesPesoDataSource(this.data);

  @override
  DataRow getRow(int index) {
    final cliente = data[index];

    return DataRow.byIndex(index: index, cells: [
      DataCell(Text(cliente['nombre'])),
      DataCell(Text(cliente['telefono'] ?? 'Desconocido')),
      DataCell(Text(cliente['peso_total'].toString())),
      DataCell(Text(cliente['total_warehouses'].toString())),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
