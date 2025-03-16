import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;

class ClientesEliminarPage extends StatefulWidget {
  const ClientesEliminarPage({super.key});

  @override
  _ClientesEliminarPageState createState() => _ClientesEliminarPageState();
}

class _ClientesEliminarPageState extends State<ClientesEliminarPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchClientesSinPeso() async {
    try {
      QuerySnapshot warehousesSnapshot = await _firestore.collection('Warehouse').get();
      Set<String> clientesConPeso = {};

      for (var doc in warehousesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String clienteId = data['cliente_id'] ?? 'Desconocido';
        double peso = data['peso_total'] ?? 0.0;

        if (peso > 0.0) {
          clientesConPeso.add(clienteId);
        }
      }

      QuerySnapshot clientesSnapshot = await _firestore.collection('Clientes').get();
      List<Map<String, dynamic>> clientesSinPeso = [];

      for (var doc in clientesSnapshot.docs) {
        String clienteId = doc.id;
        if (!clientesConPeso.contains(clienteId)) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String clienteNombre = data['nombre'] ?? 'Desconocido';
          String clienteTelefono = data['telefono'] ?? 'Desconocido';
          Timestamp fechaCreacion = data['fecha_creacion'] ?? Timestamp.now();

          clientesSinPeso.add({
            'nombre': clienteNombre,
            'telefono': clienteTelefono,
            'cliente_id': clienteId,
            'fecha_creacion': fechaCreacion,
          });
        }
      }

      return clientesSinPeso;
    } catch (e) {
      print('Error al obtener los datos de los clientes: $e');
      return [];
    }
  }

  Color getColorBasedOnDate(Timestamp fechaCreacion) {
    final now = DateTime.now();
    final creationDate = fechaCreacion.toDate();
    final difference = now.difference(creationDate).inDays;

    if (difference > 365) {
      return Colors.red.shade900;
    } else if (difference > 90) {
      return Colors.red.shade700;
    } else if (difference > 60) {
      return Colors.red.shade500;
    } else if (difference > 30) {
      return Colors.red.shade400;
    } else {
      return Colors.red.shade300;
    }
  }

  Future<void> generatePdf() async {
    try {
      final pdf = pw.Document();
      final clientesSinPeso = await fetchClientesSinPeso();
      final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

      final imageLogo = pw.MemoryImage(
        (await rootBundle.load('assets/logo_PLC.jpg')).buffer.asUint8List(),
      );

      final headers = [
        'Nombre del cliente',
        'Número',
        'Fecha de creación',
        'ID del cliente'
      ];

      final data = clientesSinPeso.map((cliente) {
        return [
          cliente['nombre'],
          cliente['telefono'],
          DateFormat('dd/MM/yyyy').format(cliente['fecha_creacion'].toDate()),
          cliente['cliente_id'],
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a3,
          margin: const pw.EdgeInsets.all(16),
          header: (context) { //ENCABEZADO DEL PDF
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(imageLogo, height: 150, width: 500),
                pw.Text(
                  'Premium Logistics Cargo',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Reporte emitido el: $formattedDate',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            );
          },
          build: (pw.Context context) {
            return [
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(150),  // Nombre del cliente
                  1: const pw.FixedColumnWidth(100),  // Número
                  2: const pw.FixedColumnWidth(100),  // Fecha de creación
                  3: const pw.FixedColumnWidth(100),  // ID del cliente
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
                          style: const pw.TextStyle(fontSize: 12),
                          softWrap: true,
                        ),
                      )).toList(),
                    );
                  }),
                ],
              ),
            ];
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
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Clientes_Sin_Peso.pdf',
      );
    } catch (e) {
      print('Error al generar el PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes sin peso en sus warehouses'),
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchClientesSinPeso(),
          builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error al obtener los datos de los clientes: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay datos disponibles', style: TextStyle(color: Colors.white)));
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final cliente = snapshot.data![index];
                final color = getColorBasedOnDate(cliente['fecha_creacion']);
                return Card(
                  color: color,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    title: Text(cliente['nombre'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Teléfono: ${cliente['telefono']}', style: const TextStyle(color: Colors.white)),
                    trailing: Text('ID: ${cliente['cliente_id']}', style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}