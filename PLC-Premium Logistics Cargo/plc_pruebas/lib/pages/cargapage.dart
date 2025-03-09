import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:plc_pruebas/services/firestore.dart';

class CargoPage extends StatefulWidget {
  final String cargaId;

  CargoPage({super.key, required this.cargaId});

  @override
  _CargoPageState createState() => _CargoPageState();
}

class _CargoPageState extends State<CargoPage> {
  final FirestoreService firestoreService = FirestoreService();

  Stream<QuerySnapshot> getWarehousesByCargoId() {
    return firestoreService.getWarehousesCarga(widget.cargaId);
  }

  List<DropdownMenuItem<String>> estatusItems = [];
  List<DropdownMenuItem<String>> modalidadItems = [];
  List<DropdownMenuItem<String>> clientItems = [];
  String? selectedEstatus;
  String? selectedModalidad;
  String? selectedClientId;

  Future<void> _loadClientes() async {
    QuerySnapshot snapshot = await firestoreService.getClientes('').first;
    setState(() {
      clientItems = snapshot.docs.map((DocumentSnapshot document) {
        String nombre = document['nombre'] ?? 'Desconocido';
        String apellido = document['apellido'] ?? '';
        String numeroIdentidad = document['numero_identidad'] ?? '';
        return DropdownMenuItem<String>(
          value: document.id,
          child: Text('$nombre $apellido ($numeroIdentidad)'),
        );
      }).toList();
      selectedClientId = clientItems.isNotEmpty ? clientItems[0].value : null;
    });
  }

  Future<void> _loadEstatus() async {
    QuerySnapshot snapshot = await firestoreService.getEstatus().first;
    setState(() {
      estatusItems = snapshot.docs.map((DocumentSnapshot document) {
        return DropdownMenuItem<String>(
          value: document.id,
          child: Text(document['Nombre']),
        );
      }).toList();
      selectedEstatus = estatusItems.isNotEmpty ? estatusItems[0].value : null;
    });
  }

  Future<void> _loadModalidades() async {
    QuerySnapshot snapshot = await firestoreService.getModalidades().first;
    setState(() {
      modalidadItems = snapshot.docs.map((DocumentSnapshot document) {
        return DropdownMenuItem<String>(
          value: document.id,
          child: Text(document['Nombre']),
        );
      }).toList();
      selectedModalidad =
          modalidadItems.isNotEmpty ? modalidadItems[0].value : null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadClientes();
    _loadEstatus();
    _loadModalidades();
  }

  Future<void> createWarehouse(BuildContext context) async {
    TextEditingController direccionController = TextEditingController();
    TextEditingController pesoController = TextEditingController();
    TextEditingController piezasController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Crear Warehouse'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Cliente'),
                      items: clientItems,
                      value: selectedClientId,
                      onChanged: (newValue) {
                        setState(() {
                          selectedClientId = newValue;
                        });
                      },
                    ),
                    TextField(
                      controller: direccionController,
                      decoration: const InputDecoration(labelText: 'Direccion'),
                    ),
                    TextField(
                      controller: pesoController,
                      decoration: const InputDecoration(labelText: 'Peso'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: piezasController,
                      decoration: const InputDecoration(labelText: 'Paquetes'),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Estatus'),
                      items: estatusItems,
                      value: selectedEstatus,
                      onChanged: (newValue) {
                        setState(() {
                          selectedEstatus = newValue;
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Modalidad'),
                      items: modalidadItems,
                      value: selectedModalidad,
                      onChanged: (newValue) {
                        setState(() {
                          selectedModalidad = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedEstatus != null &&
                        selectedModalidad != null &&
                        selectedClientId != null) {
                      await firestoreService.addWarehouse(
                        widget.cargaId,
                        selectedClientId!,
                        direccionController.text,
                        selectedEstatus!,
                        selectedModalidad!,
                        double.tryParse(pesoController.text) ?? 0,
                        int.tryParse(piezasController.text) ?? 0,
                      );
                      setState(() {
                        selectedModalidad = null;
                        selectedClientId = null;
                        selectedEstatus = null;
                        piezasController.clear();
                        pesoController.clear();
                        direccionController.clear();
                      });
                      Navigator.of(context).pop();
                    } else {
                      // Show error message if estatus, modalidad, or client is not selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Por favor seleccione Estatus, Modalidad y Cliente')),
                      );
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> getDocumentName(DocumentReference ref) async {
    DocumentSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      return snapshot['Nombre'] ?? 'Desconocido';
    }
    return 'Desconocido';
  }

  Future<String> getEstatusName(DocumentReference ref) async {
    DocumentSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      return snapshot['Nombre'] ?? 'Desconocido';
    }
    return 'Desconocido';
  }

  Future<String> getModalidadName(DocumentReference ref) async {
    DocumentSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      return snapshot['Nombre'] ?? 'Desconocido';
    }
    return 'Desconocido';
  }

  Future<String> getClientFullName(DocumentReference ref) async {
    DocumentSnapshot snapshot = await ref.get();
    if (snapshot.exists) {
      String nombre = snapshot['nombre'] ?? 'Desconocido';
      String apellido = snapshot['apellido'] ?? '';
      return '$nombre $apellido'.trim();
    }
    return 'Desconocido';
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Desconocido';
    DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }

// Agregar funciones helper para obtener nombres por ID
  Future<String> getEstatusNameById(String id) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('Estatus').doc(id).get();
    if (snapshot.exists) {
      return snapshot['Nombre'] ?? 'Desconocido';
    }
    return 'Desconocido';
  }

  Future<String> getModalidadNameById(String id) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('Modalidad').doc(id).get();
    if (snapshot.exists) {
      return snapshot['Nombre'] ?? 'Desconocido';
    }
    return 'Desconocido';
  }

  Future<String> getClientFullNameById(String id) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('Clientes').doc(id).get();
    if (snapshot.exists) {
      String nombre = snapshot['nombre'] ?? 'Desconocido';
      String apellido = snapshot['apellido'] ?? '';
      return '$nombre $apellido'.trim();
    }
    return 'Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text(
          'Cargo Warehouses',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => createWarehouse(context),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: getWarehousesByCargoId(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Error al obtener los almacenes',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No hay almacenes disponibles',
                  style: TextStyle(color: Colors.white),
                ),
              );
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
                    headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                    dataRowColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => Colors.orange.shade700.withOpacity(0.2)),
                    columns: const [
                      DataColumn2(label: Text('WarehouseID')),
                      DataColumn2(label: Text('Nombre del cliente')),
                      DataColumn2(label: Text('Direccion')),
                      DataColumn2(label: Text('Estatus')),
                      DataColumn2(label: Text('Fecha de creacion')),
                      DataColumn2(label: Text('Modalidad')),
                      DataColumn2(label: Text('Peso')),
                      DataColumn2(label: Text('Paquetes')),
                    ],
                    rows: snapshot.data!.docs.map((DocumentSnapshot document) {
                      Map<String, dynamic>? data =
                          document.data() as Map<String, dynamic>?;

                      if (data == null) {
                        return const DataRow(
                            cells: [DataCell(Text('Error al cargar datos'))]);
                      }

                      Future<String> estatusFuture = data['estatus_id'] != null
                          ? getEstatusNameById(data['estatus_id'])
                          : Future.value('Desconocido');

                      Future<String> modalidadFuture =
                          data['Modalidad'] is DocumentReference
                              ? getModalidadName(
                                  data['Modalidad'] as DocumentReference)
                              : (data['modalidad'] is String
                                  ? getModalidadNameById(data['modalidad'])
                                  : Future.value('Desconocido'));

                      Future<String> clientFuture = data['cliente_id'] != null
                          ? getClientFullNameById(data['cliente_id'])
                          : Future.value('Desconocido');

                      return DataRow(
                        cells: [
                          DataCell(
                              Text(document['warehouse_id']?.toString() ?? '')),
                          DataCell(FutureBuilder<String>(
                            future: clientFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text('Cargando...');
                              }
                              return Text(snapshot.data ?? 'Desconocido');
                            },
                          )),
                          DataCell(Text(data['direccion'] ?? 'Desconocido')),
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
                          DataCell(Text(formatDate(data['fecha']))),
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
    );
  }
}
