import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:plc_pruebas/services/firestore.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';
import 'package:sidebarx/sidebarx.dart';

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  _WarehousePageState createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  final FirestoreService firestoreService = FirestoreService();
  final SidebarXController _sidebarXController = SidebarXController(selectedIndex: 0);

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
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Estatus').doc(id).get();
    if (snapshot.exists) {
      return snapshot['Nombre'] ?? 'Desconocido';
    }
    return 'Desconocido';
  }

  Future<String> getModalidadNameById(String id) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Modalidad').doc(id).get();
    if (snapshot.exists) {
      return snapshot['Nombre'] ?? 'Desconocido';
    }
    return 'Desconocido';
  }

  Future<String> getClientFullName(String clientId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Clientes').doc(clientId).get();
    if (snapshot.exists && snapshot.data() != null) {
      Map<String, dynamic> clientData = snapshot.data() as Map<String, dynamic>;
      String nombre = clientData['nombre'] ?? clientData['Nombre'] ?? '';
      String apellido = clientData['apellido'] ?? clientData['Apellido'] ?? '';
      String fullName = '$nombre $apellido'.trim();
      return fullName.isEmpty ? 'Desconocido' : fullName;
    }
    return 'Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse'),
      ),
      drawer: Sidebar(selectedIndex: 2, controller: _sidebarXController),
      body: StreamBuilder<QuerySnapshot>(
        stream: getWare(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al obtener los almacenes'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay almacenes disponibles'));
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
                  columns: const [
                    DataColumn2(label: Text('WarehouseID')),
                    DataColumn2(label: Text('CargaID')),
                    DataColumn2(label: Text('Nombre del cliente')),
                    DataColumn2(label: Text('Direccion')),
                    DataColumn2(label: Text('Estatus')),
                    DataColumn2(label: Text('Fecha de creacion')),
                    DataColumn2(label: Text('Modalidad')),
                    DataColumn2(label: Text('Peso')),
                    DataColumn2(label: Text('Paquetes')),
                  ],
                  rows: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

                    if (data == null) return const DataRow(cells: [DataCell(Text('Error al cargar datos'))]);

                    Future<String> estatusFuture = data['estatus_id'] != null
                        ? getEstatusNameById(data['estatus_id'])
                        : Future.value('Desconocido');
                    
                    Future<String> modalidadFuture = data['modalidad'] is DocumentReference
                        ? getModalidadNameById((data['modalidad'] as DocumentReference).id)
                        : (data['modalidad'] is String
                            ? getModalidadNameById(data['modalidad'])
                            : Future.value('Desconocido'));

                    Future<String> clientFuture = data['cliente_id'] != null
                        ? (data['cliente_id'] is DocumentReference
                            ? getClientFullName((data['cliente_id'] as DocumentReference).id)
                            : getClientFullName(data['cliente_id']))
                        : Future.value('Desconocido');

                    String cargaId = "Desconocido";
                    if (data['CargaID'] is DocumentReference) {
                      cargaId = (data['CargaID'] as DocumentReference).id;
                    } else if (data['carga_id'] is String) {
                      cargaId = data['carga_id'];
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(document['warehouse_id'])),
                        DataCell(Text(cargaId)),
                        DataCell(FutureBuilder<String>(
                          future: clientFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done) {
                              return const Text('Cargando...');
                            }
                            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                              return const Text('Desconocido');
                            }
                            return Text(snapshot.data!);
                          },
                        )),
                        DataCell(Text(data['direccion'] ?? 'Desconocido')),
                        DataCell(FutureBuilder<String>(
                          future: estatusFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Cargando...');
                            }
                            return Text(snapshot.data ?? 'Desconocido');
                          },
                        )),
                        DataCell(Text(formatDate(data['fecha']))),
                        DataCell(FutureBuilder<String>(
                          future: modalidadFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Cargando...');
                            }
                            return Text(snapshot.data ?? 'Desconocido');
                          },
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
    );
  }
}