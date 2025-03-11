import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    } else if (difference > 180) {
      return Colors.red.shade700;
    } else if (difference > 90) {
      return Colors.red.shade500;
    } else if (difference > 30) {
      return Colors.red.shade300;
    } else {
      return Colors.red.shade100;
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
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchClientesSinPeso(),
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al obtener los datos de los clientes: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay datos disponibles'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final cliente = snapshot.data![index];
              final color = getColorBasedOnDate(cliente['fecha_creacion']);
              return Card(
                color: color,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(cliente['nombre']),
                  subtitle: Text('Teléfono: ${cliente['telefono']}'),
                  trailing: Text('ID: ${cliente['cliente_id']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}