import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:sidebarx/sidebarx.dart';
import '../services/firestore.dart';
import '../widgets/sidebar.dart';

class CargasPage extends StatefulWidget {
  const CargasPage({super.key});
  @override
  _CargasPageState createState() => _CargasPageState();
}

class _CargasPageState extends State<CargasPage> {
  final FirestoreService firestoreService = FirestoreService();
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 0);

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

  String formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
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
                          DataColumn(
                              label: Text('ID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Fecha en almacen',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Fecha de Entrega',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Estatus',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Modalidad',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Peso',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Piezas',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: snapshot.data!.docs
                            .map((DocumentSnapshot document) {
                          Map<String, dynamic>? data =
                              document.data() as Map<String, dynamic>?;
                          if (data == null)
                            return const DataRow(cells: [
                              DataCell(Text('Error al cargar datos'))
                            ]);

                          Future<String> estatusFuture =
                              data['EstatusID'] is DocumentReference
                                  ? getDocumentName(
                                      data['EstatusID'] as DocumentReference)
                                  : Future.value(
                                      data['EstatusID'] ?? 'Desconocido');

                          Future<String> modalidadFuture =
                              data['Modalidad'] is DocumentReference
                                  ? getDocumentName(
                                      data['Modalidad'] as DocumentReference)
                                  : Future.value(
                                      data['Modalidad'] ?? 'Desconocido');

                          return DataRow(cells: [
                            DataCell(Text(document.id)),
                            DataCell(Text(formatDate(data['Fecha_Inicial']))),
                            DataCell(Text(formatDate(data['Fecha_Final']))),
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
                            DataCell(Text(data['Peso'].toString())),
                            DataCell(Text(data['Piezas'].toString())),
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
    );
  }
}
