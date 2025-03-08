import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';

class PaquetesPage extends StatefulWidget {
  const PaquetesPage({super.key});
  @override
  _PaquetesPageState createState() => _PaquetesPageState();
}

class _PaquetesPageState extends State<PaquetesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPaq() {
    return _firestore.collection('Paquetes').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paquetes')),
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

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
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
                  rows: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

                    if (data == null) return DataRow(cells: [DataCell(Text('Error al cargar datos'))]);

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
