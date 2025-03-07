import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:plc_pruebas/services/firestore.dart';
import 'package:plc_pruebas/controllers/controladores.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Firestore data service
  final FirestoreService firestoreService = FirestoreService();

  // Controladores
  final ControladorPaquetes controladorPaquete = ControladorPaquetes();

  // Variable para modalidad de envío
  String modalidadEnvio = 'Marítimo';

  //box para agregar un nuevo paquete
  void nuevoPaquete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Paquete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: controladorPaquete.traking_numberController,
              decoration: const InputDecoration(labelText: 'Traking Number'),
            ),
            TextField(
              controller: controladorPaquete.warehouseIDController,
              decoration: const InputDecoration(labelText: 'Warehouse ID'),
            ),
            TextField(
              controller: controladorPaquete.pesoController,
              decoration: const InputDecoration(labelText: 'Peso'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: controladorPaquete.tipoController,
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            DropdownButton<String>(
              value: modalidadEnvio,
              onChanged: (String? newValue) {
                setState(() {
                  modalidadEnvio = newValue!;
                });
              },
              items: <String>['Marítimo', 'Aéreo']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Validar que el peso sea un número mayor que 0
              double peso = double.tryParse(controladorPaquete.pesoController.text) ?? -1;
              if (peso <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El peso debe ser un número mayor que 0')),
                );
                return;
              }

              //LLAMAR A LA FUNCIÓN DE FIRESTORE PARA AGREGAR EL PAQUETE
              firestoreService.addPaquete(
                controladorPaquete.traking_numberController.text,
                controladorPaquete.warehouseIDController.text,
                controladorPaquete.direccionController.text,
                double.parse(controladorPaquete.pesoController.text),
                controladorPaquete.tipoController.text,
                modalidadEnvio,
              );
              // Limpiar los controladores después de agregar el paquete
              controladorPaquete.traking_numberController.clear();
              controladorPaquete.warehouseIDController.clear();
              controladorPaquete.pesoController.clear();
              controladorPaquete.tipoController.clear();
              modalidadEnvio = 'Marítimo';
              Navigator.of(context).pop();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pruebas de PLC'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: nuevoPaquete,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: firestoreService.getPaquetes(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError) {
            return const Text('Error al obtener los paquetes');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data.docs.map<Widget>((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['nombre']),
                subtitle: Text(data['warehouse_id']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Lógica para editar el paquete
                        // Puedes abrir un diálogo similar al de nuevoPaquete para editar los datos
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // Lógica para eliminar el paquete
                        firestoreService.deletePaquete(document.id);
                      },
                    ),
                    Text(data['peso'].toString()),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
