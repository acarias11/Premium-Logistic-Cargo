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

          clientesSinPeso.add({
            'nombre': clienteNombre,
            'telefono': clienteTelefono,
            'cliente_id': clienteId,
          });
        }
      }

      return clientesSinPeso;
    } catch (e) {
      print('Error al obtener los datos de los clientes: $e');
      return [];
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
              return ListTile(
                title: Text(cliente['nombre']),
                subtitle: Text('Teléfono: ${cliente['telefono']}'),
                trailing: Text('ID: ${cliente['cliente_id']}'),
              );
            },
          );
        },
      ),
    );
  }
}