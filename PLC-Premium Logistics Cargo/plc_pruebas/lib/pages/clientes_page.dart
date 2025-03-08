import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:plc_pruebas/services/firestore.dart';
import 'package:plc_pruebas/controllers/controladores.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:intl/date_symbol_data_local.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});
  @override
  _ClientesPageState createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService firestoreService = FirestoreService();
  final ControladorClientes controladorCliente = ControladorClientes();
  final SidebarXController _sidebarXController = SidebarXController(selectedIndex: 0);
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
  }

  //box para agregar un nuevo cliente
  void nuevoCliente() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: controladorCliente.nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: controladorCliente.apellidoController,
              decoration: const InputDecoration(labelText: 'Apellido'),
            ),
            TextField(
              controller: controladorCliente.emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: controladorCliente.numero_identidadController,
              decoration: const InputDecoration(labelText: 'Número de Identidad'),
            ),
            TextField(
              controller: controladorCliente.telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            TextField(
              controller: controladorCliente.direccionController,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
            TextField(
              controller: controladorCliente.ciudadController,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            TextField(
              controller: controladorCliente.departamentoController,
              decoration: const InputDecoration(labelText: 'Departamento'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'País'),
              enabled: false,
              controller: TextEditingController(text: 'Honduras'),
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
              // Validar que los campos no estén vacíos
              if (controladorCliente.nombreController.text.isEmpty ||
                  controladorCliente.apellidoController.text.isEmpty ||
                  controladorCliente.emailController.text.isEmpty ||
                  controladorCliente.numero_identidadController.text.isEmpty ||
                  controladorCliente.telefonoController.text.isEmpty ||
                  controladorCliente.direccionController.text.isEmpty ||
                  controladorCliente.ciudadController.text.isEmpty ||
                  controladorCliente.departamentoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Todos los campos son obligatorios')),
                );
                return;
              }

              //LLAMAR A LA FUNCIÓN DE FIRESTORE PARA AGREGAR EL CLIENTE
              firestoreService.addCliente(
                controladorCliente.nombreController.text,
                controladorCliente.apellidoController.text,
                controladorCliente.emailController.text,
                controladorCliente.numero_identidadController.text,
                controladorCliente.telefonoController.text,
                controladorCliente.direccionController.text,
                controladorCliente.ciudadController.text,
                controladorCliente.departamentoController.text,
                'Honduras',
              );
              // Limpiar los controladores después de agregar el cliente
              controladorCliente.nombreController.clear();
              controladorCliente.apellidoController.clear();
              controladorCliente.emailController.clear();
              controladorCliente.numero_identidadController.clear();
              controladorCliente.telefonoController.clear();
              controladorCliente.direccionController.clear();
              controladorCliente.ciudadController.clear();
              controladorCliente.departamentoController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> getClientes() {
    return _firestore.collection('Clientes').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o apellido',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.toUpperCase();
                });
              },
            ),
          ),
        ),
      ),
      drawer: Sidebar(selectedIndex: 3, controller: _sidebarXController),
      floatingActionButton: FloatingActionButton(
        onPressed: nuevoCliente,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getClientes(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al obtener los clientes'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay clientes disponibles'));
          }

          var filteredDocs = snapshot.data!.docs.where((DocumentSnapshot document) {
            Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;
            if (data == null) return false;

            String nombre = data['nombre']?.toString() ?? '';
            String apellido = data['apellido']?.toString() ?? '';

            return nombre.toUpperCase().contains(_searchText) || apellido.toUpperCase().contains(_searchText);
          }).toList();

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
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Apellido')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Número de Identidad')),
                    DataColumn(label: Text('Teléfono')),
                    DataColumn(label: Text('Dirección')),
                    DataColumn(label: Text('Ciudad')),
                    DataColumn(label: Text('Departamento')),
                    DataColumn(label: Text('País')),
                  ],
                  rows: filteredDocs.map((DocumentSnapshot document) {
                    Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

                    if (data == null) return const DataRow(cells: [DataCell(Text('Error al cargar datos'))]);

                    return DataRow(cells: [
                      DataCell(Text(data['nombre']?.toString() ?? 'Sin Nombre')),
                      DataCell(Text(data['apellido']?.toString() ?? 'Sin Apellido')),
                      DataCell(Text(data['email']?.toString() ?? 'Sin Email')),
                      DataCell(Text(data['numero_identidad']?.toString() ?? 'Sin Número de Identidad')),
                      DataCell(Text(data['telefono']?.toString() ?? 'Sin Teléfono')),
                      DataCell(Text(data['direccion']?.toString() ?? 'Sin Dirección')),
                      DataCell(Text(data['ciudad']?.toString() ?? 'Sin Ciudad')),
                      DataCell(Text(data['departamento']?.toString() ?? 'Sin Departamento')),
                      DataCell(Text(data['pais']?.toString() ?? 'Honduras')),
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
