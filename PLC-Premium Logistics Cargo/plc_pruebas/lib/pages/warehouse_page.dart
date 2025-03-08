import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:plc_pruebas/services/firestore.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';
import 'package:sidebarx/sidebarx.dart';

import '../services/firestore.dart';
import '../widgets/sidebar.dart';

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  _WarehousePageState createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  final FirestoreService firestoreService = FirestoreService();
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 0);

  Stream<QuerySnapshot> getWare() {
    return firestoreService.getWarehouses();
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Sujeta a cambio';
    }
    DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<String> getEstatusNameById(String id) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('Estatus').doc(id).get();
    return snapshot.exists
        ? (snapshot['Nombre'] ?? 'Desconocido')
        : 'Desconocido';
  }

  Future<String> getModalidadNameById(String id) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('Modalidad').doc(id).get();
    return snapshot.exists
        ? (snapshot['Nombre'] ?? 'Desconocido')
        : 'Desconocido';
  }

  Future<String> getClientFullName(String clientId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('Clientes')
        .doc(clientId)
        .get();
    if (snapshot.exists && snapshot.data() != null) {
      Map<String, dynamic> clientData = snapshot.data() as Map<String, dynamic>;
      String nombre = clientData['nombre'] ?? clientData['Nombre'] ?? '';
      String apellido = clientData['apellido'] ?? clientData['Apellido'] ?? '';
      return '$nombre $apellido'.trim().isEmpty
          ? 'Desconocido'
          : '$nombre $apellido';
    }
    return 'Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Sidebar(selectedIndex: 2, controller: _sidebarXController),
      body: Column(
        children: [
          AppBar(
            title:
                const Text('Warehouse', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange.shade700,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getWare(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error al obtener los almacenes'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No hay almacenes disponibles'));
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
                          DataColumn2(
                              label: Text('WarehouseID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('CargaID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Nombre del cliente',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Dirección',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Estatus',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn2(
                              label: Text('Fecha de creación',
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
                              label: Text('Paquetes',
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

                          return DataRow(
                            cells: [
                              DataCell(Text(document['warehouse_id'])),
                              DataCell(Text(data['CargaID']?.toString() ??
                                  'Desconocido')),
                              DataCell(FutureBuilder(
                                future:
                                    getClientFullName(data['cliente_id'] ?? ''),
                                builder: (context, snapshot) =>
                                    Text(snapshot.data ?? 'Cargando...'),
                              )),
                              DataCell(
                                  Text(data['direccion'] ?? 'Desconocido')),
                              DataCell(FutureBuilder(
                                future: getEstatusNameById(
                                    data['estatus_id'] ?? ''),
                                builder: (context, snapshot) =>
                                    Text(snapshot.data ?? 'Cargando...'),
                              )),
                              DataCell(Text(formatDate(data['fecha']))),
                              DataCell(FutureBuilder(
                                future: getModalidadNameById(
                                    data['modalidad'] ?? ''),
                                builder: (context, snapshot) =>
                                    Text(snapshot.data ?? 'Cargando...'),
                              )),
                              DataCell(Text(data['peso_total'].toString())),
                              DataCell(Text(data['piezas'].toString())),
                            ],
                          );
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
