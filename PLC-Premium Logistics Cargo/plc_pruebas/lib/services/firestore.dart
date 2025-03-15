import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Colecciones
  late final CollectionReference estatus;
  late final CollectionReference modalidad;
  late final CollectionReference warehouse;
  late final CollectionReference paquetes;
  late final CollectionReference clientes;
  late final CollectionReference cargas;
  late final CollectionReference tipo;

  FirestoreService() {
    estatus = _db.collection('Estatus');
    modalidad = _db.collection('Modalidad');
    warehouse = _db.collection('Warehouse');
    paquetes = _db.collection('Paquetes');
    clientes = _db.collection('Clientes');
    cargas = _db.collection('Carga');
    tipo = _db.collection('Tipo_Paquetes');
  }

  // Mapas de estatus y modalidades
  final Map<String, String> estatusMap = {
    'EST1': 'Completado',
    'EST2': 'En Transito',
    'EST3': 'En Bodega',
  };

  final Map<String, String> modalidadMap = {
    'MOD1': 'Aéreo',
    'MOD2': 'Marítimo',
    'MOD3': 'Terrestre',
  };

  Future<String> getEstatusNameById(String id) async {
    return estatusMap[id] ?? 'Desconocido';
  }

  Future<String> getModalidadNameById(String id) async {
    return modalidadMap[id] ?? 'Desconocido';
  }

  Future<String> getWarehouseNameById(String id) async {
    DocumentSnapshot snapshot = await warehouse.doc(id).get();
    if (snapshot.exists) {
      return snapshot['nombre'] ?? 'Desconocido';
    }
    return 'Desconocido';
  }

  // CREATE: agregar nuevo paquete
  Future<void> addPaquete(
    String trackingNumber,
    String warehouseId,
    String direccion,
    double peso,
    String tipo,
  ) async {
    try {
      DocumentSnapshot warehouseSnapshot = await warehouse.doc(warehouseId).get();
      if (!warehouseSnapshot.exists) {
        throw Exception('El warehouse con ID $warehouseId no existe');
      }

      // Obtener el estatus y modalidad del warehouse
      String estatusID = warehouseSnapshot['estatus_id'] ?? 'Desconocido';
      String modalidadEnvio = warehouseSnapshot['modalidad'] ?? 'Desconocido';

      // Obtener el siguiente paquete_id
      String paqueteId = await _getNextPaqueteId();
      DateTime fecha = DateTime.now(); // Obtener la fecha y hora actual

      await paquetes.doc(paqueteId).set({
        'paquete_id': paqueteId,
        'TrakingNumber': trackingNumber,
        'Fecha': fecha,
        'WarehouseID': warehouseId,
        'Peso': peso,
        'Tipo': tipo,
        'Modalidad': modalidadEnvio,
        'Direccion': direccion,
        'EstatusID': estatusID,
      }).then((_) {
        print('Paquete agregado exitosamente');
      }).catchError((e) {
        print('Error al agregar paquete: $e');
      });
    } catch (e) {
      print('Error al agregar paquete: $e');
      rethrow;
    }
  }

  Future<String> _getNextPaqueteId() async {
    QuerySnapshot querySnapshot = await paquetes.orderBy('paquete_id', descending: true).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      String lastPaqueteId = querySnapshot.docs.first['paquete_id'];
      int nextId = int.parse(lastPaqueteId.replaceAll('PKG', '')) + 1;
      return 'PKG$nextId';
    } else {
      return 'PKG1';
    }
  }

  // READ: obtener todos los paquetes por el id del documento
  Stream<QuerySnapshot> getPaquetes() {
    return paquetes.orderBy('paquete_id', descending: true).snapshots();
  }

  // READ: obtener todos los estatus
  Stream<QuerySnapshot> getEstatus() {
    return estatus.snapshots();
  }

  // READ: obtener todas las modalidades
  Stream<QuerySnapshot> getModalidades() {
    return modalidad.snapshots();
  }

  Future<String> getModalidadIdByName(String name) async {
    // Usar la colección "Modalidad" en singular
    QuerySnapshot snapshot = await _db.collection('Modalidad').where('Nombre', isEqualTo: name).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return 'Desconocido';
  }

  // UPDATE: actualizar paquete
  Future<void> updatePaquete(String paqueteId, String trackingNumber, String warehouseId, String direccion, double peso, String tipo, String modalidadEnvio, String estatusID) {
    return paquetes.doc(paqueteId).update({
      'tracking_number': trackingNumber,
      'warehouse_id': warehouseId,
      'peso': peso,
      'tipo': tipo,
      'modalidad': modalidadEnvio,
      'direccion': direccion,
      'estatus_id': estatusID
    }).then((_) {
      print('Paquete actualizado exitosamente');
    }).catchError((e) {
      print('Error al actualizar paquete: $e');
    });
  }

  // Funcion para obtener la modalidad de todos los paquetes
  Stream<QuerySnapshot> getModalidadPaquetes() {
    return modalidad.snapshots();
  }

  // Funcion para agregar un paquete a un warehouse
  Future<void> addPaqueteToWarehouse(String paqueteId, String warehouseId) {
    return paquetes.doc(paqueteId).update({
      'warehouse_id': warehouseId
    }).then((_) {
      print('Paquete agregado al warehouse exitosamente');
    }).catchError((e) {
      print('Error al agregar paquete al warehouse: $e');
    });
  }

  // DELETE: eliminar paquete
  Future<void> deletePaquete(String paqueteId) {
    return paquetes.doc(paqueteId).delete().then((_) {
      print('Paquete eliminado exitosamente');
    }).catchError((e) {
      print('Error al eliminar paquete: $e');
    });
  }

  // CREATE: agregar nuevo cliente  
  // Se corrige el nombre del campo "ciudad" (antes "cuidad")
  Future<void> addCliente(String nombre, String apellido, String numeroIdentidad, String email, String telefono, String direccion, String ciudad, String departamento, String pais) async {
    String clienteId = await _getNextClienteId(); // Obtener el siguiente cliente_id
    DateTime fecha = DateTime.now(); // Obtener la fecha y hora actual
    return clientes.doc(clienteId).set({
      'cliente_id': clienteId,
      'nombre': nombre,
      'apellido': apellido,
      'numero_identidad': numeroIdentidad,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'ciudad': ciudad, // Clave corregida
      'departamento': departamento,
      'pais': 'Honduras',
      'fecha': fecha
    }).then((_) {
      print('Cliente agregado exitosamente');
    }).catchError((e) {
      print('Error al agregar cliente: $e');
    });
  }

  // Función para obtener el siguiente cliente_id
  Future<String> _getNextClienteId() async {
    QuerySnapshot querySnapshot = await clientes.orderBy('cliente_id', descending: true).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      String lastClienteId = querySnapshot.docs.first['cliente_id'];
      int nextId = int.parse(lastClienteId.replaceAll('CLR', '')) + 1;
      return 'CLR$nextId';
    } else {
      return 'CLR1';
    }
  }

  // READ: obtener todos los clientes
  Stream<QuerySnapshot> getClientes(String text) {
    final clientestream = clientes.orderBy('cliente_id', descending: true).snapshots();
    return clientestream;
  }

  // Funcion para obtener la fecha de todos los clientes
  Stream<QuerySnapshot> getFechaClientes() {
    return clientes.snapshots();
  }

  // UPDATE: actualizar cliente
  Future<void> updateCliente(String clienteId, String nombre, String apellido, String numeroIdentidad, String email, String telefono, String direccion, String ciudad, String departamento, String pais) {
    return clientes.doc(clienteId).update({
      'nombre': nombre,
      'apellido': apellido,
      'numero_identidad': numeroIdentidad,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'ciudad': ciudad, // Clave corregida
      'departamento': departamento,
      'pais': 'Honduras'
    }).then((_) {
      print('Cliente actualizado exitosamente');
    }).catchError((e) {
      print('Error al actualizar cliente: $e');
    });
  }

  // DELETE: eliminar cliente
  Future<void> deleteCliente(String clienteId) {
    return clientes.doc(clienteId).delete().then((_) {
      print('Cliente eliminado exitosamente');
    }).catchError((e) {
      print('Error al eliminar cliente: $e');
    });
  }

  Future<DocumentSnapshot> getClientById(String clientId) async {
    return await _db.collection('Clientes').doc(clientId).get();
  }

  Future<String> getClientFullNameById(String clientId) async {
    DocumentSnapshot clientDoc = await getClientById(clientId);
    if (clientDoc.exists) {
      String nombre = clientDoc['nombre'] ?? 'Desconocido';
      String apellido = clientDoc['apellido'] ?? '';
      return '$nombre $apellido';
    }
    return 'Desconocido';
  }

  // CREATE: agregar nueva carga
  Future<void> addCarga(String entregaInicial, String entregaFinal, String estatusNombre, String fechaInicial, String fechaFinal, String modalidadNombre, double peso, int piezas) async {
    // Mapas de estatus y modalidades locales
    final Map<String, String> estatusMapLocal = {
      'Completado': 'EST1',
      'En Transito': 'EST2',
      'En Bodega': 'EST3',
    };

    final Map<String, String> modalidadMapLocal = {
      'Aereo': 'MOD1',
      'Maritimo': 'MOD2',
    };

    // Convertir nombres legibles a IDs
    String estatusID = estatusMapLocal[estatusNombre] ?? 'Desconocido';
    String modalidadID = modalidadMapLocal[modalidadNombre] ?? 'Desconocido';

    // Obtener el siguiente carga_id
    String cargaId = await _getNextCargaId();
    DateTime fecha = DateTime.now(); // Obtener la fecha y hora actual

    return cargas.doc(cargaId).set({
      'carga_id': cargaId,
      'entrega_inicial': entregaInicial,
      'entrega_final': entregaFinal,
      'estatus_id': estatusID,
      'fecha_inicial': fechaInicial,
      'fecha_final': fechaFinal,
      'modalidad': modalidadID,
      'peso': peso,
      'piezas': piezas,
      'fecha': fecha
    }).then((_) {
      print('Carga agregada exitosamente');
    }).catchError((e) {
      print('Error al agregar carga: $e');
    });
  }

  // Función para obtener el siguiente carga_id
  Future<String> _getNextCargaId() async {
    QuerySnapshot querySnapshot = await cargas.orderBy('carga_id', descending: true).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      String lastCargaId = querySnapshot.docs.first['carga_id'];
      int nextId = int.parse(lastCargaId.replaceAll('CRG', '')) + 1;
      return 'CRG$nextId';
    } else {
      return 'CRG1';
    }
  }

  // READ: obtener todas las cargas
  Stream<QuerySnapshot> getCargas() {
    return cargas.snapshots();
  }

  // UPDATE: actualizar carga  
  Future<void> updateCarga(String cargaId, String entregaInicial, String entregaFinal, String estatusID, String fechaInicial, String fechaFinal, String modalidad, double peso, int piezas) {
    return cargas.doc(cargaId).update({
      'entrega_inicial': entregaInicial,
      'entrega_final': entregaFinal,
      'estatus_id': estatusID,
      'fecha_inicial': fechaInicial,
      'fecha_final': fechaFinal,
      'modalidad': modalidad,
      'peso': peso,
      'piezas': piezas
    }).then((_) {
      print('Carga actualizada exitosamente');
    }).catchError((e) {
      print('Error al actualizar carga: $e');
    });
  }

  // DELETE: eliminar carga
  Future<void> deleteCarga(String cargaId) {
    return cargas.doc(cargaId).delete().then((_) {
      print('Carga eliminada exitosamente');
    }).catchError((e) {
      print('Error al eliminar carga: $e');
    });
  }

  Future<double> _calculateTotalWeight(String warehouseID) async {
    QuerySnapshot querySnapshot = await paquetes.where('warehouse_id', isEqualTo: warehouseID).get();
    double totalWeight = 0;
    for (var doc in querySnapshot.docs) {
      totalWeight += doc['peso'];
    }
    return totalWeight;
  }

  Future<num> _calculateTotalPieces(String warehouseID) async {
    QuerySnapshot querySnapshot = await paquetes.where('warehouse_id', isEqualTo: warehouseID).get();
    num totalPieces = 0;
    for (var doc in querySnapshot.docs) {
      totalPieces += doc['piezas'];
    }
    return totalPieces;
  }

  // CREATE: agregar nuevo warehouse 
  Future<void> addWarehouse(String cargaID, String clienteID, double pesoTotal, num piezas) async {
    DocumentSnapshot cargaSnapshot = await cargas.doc(cargaID).get();
    DocumentSnapshot clienteSnapshot = await clientes.doc(clienteID).get();
    if (!cargaSnapshot.exists) {
      print('Error: La carga con ID $cargaID no existe');
      return;
    }
    String estatusID = cargaSnapshot['estatus_id'];
    String modalidadValue = cargaSnapshot['modalidad'];
    String direccion = clienteSnapshot['direccion'];

    
    String warehouseID = await _getNextWarehouseId(); // Obtener el siguiente warehouse_id
    DateTime fecha = DateTime.now(); // Obtener la fecha y hora actual
    return warehouse.doc(warehouseID).set({
      'warehouse_id': warehouseID,
      'carga_id': cargaID,
      'cliente_id': clienteID,
      'direccion': direccion,
      'estatus_id': estatusID,
      'fecha': fecha,
      'modalidad': modalidadValue,
      'peso_total': pesoTotal,
      'piezas': piezas
    }).then((_) {
      print('Warehouse agregado exitosamente');
    }).catchError((e) {
      print('Error al agregar warehouse: $e');
    });
  }

  // Función para obtener el siguiente warehouse_id
  Future<String> _getNextWarehouseId() async {
    QuerySnapshot querySnapshot = await warehouse.get();
    int maxId = 0;
    for (var doc in querySnapshot.docs) {
      String currentId = doc['warehouse_id'] as String;
      int idNum = int.tryParse(currentId.replaceAll('WRH', '')) ?? 0;
      if (idNum > maxId) {
        maxId = idNum;
      }
    }
    return 'WRH${maxId + 1}';
  }

  // READ: obtener todos los warehouses
  Stream<QuerySnapshot> getWarehouses() {
    return warehouse.snapshots();
  }

  // UPDATE: actualizar warehouse
  Future<void> updateWarehouse(String warehouseId, String cargaID, String clienteID, String direccion, String estatusID, String modalidadValue, double pesoTotal, int piezas) async {
    return warehouse.doc(warehouseId).update({
      'carga_id': cargaID,
      'cliente_id': clienteID,
      'direccion': direccion,
      'estatus_id': estatusID,
      'modalidad': modalidadValue,
      'piezas': piezas
    }).then((_) {
      print('Warehouse actualizado exitosamente');
    }).catchError((e) {
      print('Error al actualizar warehouse: $e');
    });
  }

  // DELETE: eliminar warehouse
  Future<void> deleteWarehouse(String warehouseId) {
    return warehouse.doc(warehouseId).delete().then((_) {
      print('Warehouse eliminado exitosamente');
    }).catchError((e) {
      print('Error al eliminar warehouse: $e');
    });
  }

  // READ: obtener todos los paquetes de un warehouse
  Stream<QuerySnapshot> getPaquetesWarehouse(String warehouseId) {
    return paquetes.where('warehouse_id', isEqualTo: warehouseId).snapshots();
  }

  // READ: obtener todos los warehouses de un cliente
  Stream<QuerySnapshot> getWarehousesCliente(String clienteId) {
    return warehouse.where('cliente_id', isEqualTo: clienteId).snapshots();
  }

  // READ: obtener todos los paquetes de un cliente
  Stream<QuerySnapshot> getPaquetesCliente(String clienteId) {
    return paquetes.where('cliente_id', isEqualTo: clienteId).snapshots();
  }

  // READ: obtener todos los paquetes de una carga
  Stream<QuerySnapshot> getPaquetesCarga(String cargaId) {
    return paquetes.where('carga_id', isEqualTo: cargaId).snapshots();
  }

  // READ: obtener todas las cargas de un cliente
  Stream<QuerySnapshot> getCargasCliente(String clienteId) {
    return cargas.where('cliente_id', isEqualTo: clienteId).snapshots();
  }

  // READ: obtener todos los warehouses de una carga
  Stream<QuerySnapshot> getWarehousesCarga(String cargaId) {
    return warehouse.where('carga_id', isEqualTo: cargaId).snapshots();
  }

  getEstatusIdByName(String s) {}
}
