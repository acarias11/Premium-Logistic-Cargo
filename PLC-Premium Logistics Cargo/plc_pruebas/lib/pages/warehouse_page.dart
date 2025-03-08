import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:plc_pruebas/services/firestore.dart';

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  _WarehousePageState createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  final FirestoreService firestoreService = FirestoreService();

  Stream<QuerySnapshot> getWare() {
    return firestoreService.getWarehouses();
  }

  Future<String> getDocumentName(DocumentReference ref) async {
    DocumentSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      return snapshot['Nombre'] ?? 'Desconocido';
    }
    return 'Desconocido';
  }

  Future<String> getClientFullName(DocumentReference ref) async {
    DocumentSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      String nombre = snapshot['Nombre'] ?? 'Desconocido';
      String apellido = snapshot['Apellido'] ?? '';
      return '$nombre $apellido'.trim();
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
      appBar: AppBar(
        title: const Text('Warehouse'),
      ),
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
                width: MediaQuery.of(context).size.width, // Asegura que el DataTable2 tenga un ancho adecuado
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

                    Future<String> estatusFuture = data['EstatusID'] is DocumentReference
                        ? getDocumentName(data['EstatusID'] as DocumentReference)
                        : Future.value(data['EstatusID'] ?? 'Desconocido');

                    Future<String> modalidadFuture = data['Modalidad'] is DocumentReference
                        ? getDocumentName(data['Modalidad'] as DocumentReference)
                        : Future.value(data['Modalidad'] ?? 'Desconocido');

                    Future<String> clientFuture = data['ClienteID'] is DocumentReference
                        ? getClientFullName(data['ClienteID'] as DocumentReference)
                        : Future.value(data['ClienteID'] ?? 'Desconocido');

                    String cargaId = "Desconocido";
                    if (data['CargaID'] is DocumentReference) {
                      cargaId = (data['CargaID'] as DocumentReference).id;
                    } else if (data['CargaID'] is String) {
                      cargaId = data['CargaID'];
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(document.id)),
                        DataCell(Text(cargaId)),
                        DataCell(FutureBuilder<String>(
                          future: clientFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Cargando...');
                            }
                            return Text(snapshot.data ?? 'Desconocido');
                          },
                        )),
                        DataCell(Text(data['Direccion'] ?? 'Desconocido')),
                        DataCell(FutureBuilder<String>(
                          future: estatusFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Cargando...');
                            }
                            return Text(snapshot.data ?? 'Desconocido');
                          },
                        )),
                        DataCell(Text(formatDate(data['Fecha']))),
                        DataCell(FutureBuilder<String>(
                          future: modalidadFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Cargando...');
                            }
                            return Text(snapshot.data ?? 'Desconocido');
                          },
                        )),
                        DataCell(Text(data['PesoTotal'].toString())),
                        DataCell(Text(data['Piezas'].toString())),
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