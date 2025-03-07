import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  //get collection reference
  final CollectionReference paquetes = FirebaseFirestore.instance.collection('Paquetes');
  final CollectionReference clientes = FirebaseFirestore.instance.collection('Clientes');
  final CollectionReference cargas = FirebaseFirestore.instance.collection('Carga');
  final CollectionReference warehouse = FirebaseFirestore.instance.collection('Warehouse');
  final CollectionReference estatus = FirebaseFirestore.instance.collection('Estatus');
  final CollectionReference modalidad = FirebaseFirestore.instance.collection('Modalidad');
  final CollectionReference tipo = FirebaseFirestore.instance.collection('Tipo_Paquetes');

  //CREATE: agregar nuevo paquete
  Future<void> addPaquete(String trakingNumber, String warehouseId, String direccion, double peso, String tipo, String modalidadEnvio, String estatusID) async {
    String paqueteId = await _getNextPaqueteId(); // Obtener el siguiente paquete_id
    DateTime fecha = DateTime.now(); // Obtener la fecha y hora actual

    return paquetes.add({
      'paquete_id': paqueteId,
      'TrakingNumber': trakingNumber,
      'Fecha': fecha,
      'WarehouseID': warehouseId,
      'Peso': peso,
      'Tipo': tipo,
      'Modalidad': modalidadEnvio,
      'Direccion': direccion,
      'EstatusID': estatusID
    }).then((_) {
      print('Paquete agregado exitosamente');
    }).catchError((e) {
      print('Error al agregar paquete: $e');
    });
  }

  // Función para obtener el siguiente paquete_id 
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

  //READ: obtener todos los paquetes
  Stream<QuerySnapshot> getPaquetes() {
    final paquestream = paquetes.orderBy('fecha', descending: true).snapshots();
    return paquestream;
  }

  //UPDATE: actualizar paquete
  Future<void> updatePaquete(String paqueteId, String trakingNumber, String warehouseId, String direccion, double peso, String tipo, String modalidadEnvio, String estatusID) {
    return paquetes.doc(paqueteId).update({
      'TrakingNumber': trakingNumber,
      'WarehouseID': warehouseId,
      'Peso': peso,
      'Tipo': tipo,
      'Modalidad': modalidadEnvio,
      'Direccion': direccion,
      'EstatusID': estatusID
    }).then((_) {
      print('Paquete actualizado exitosamente');
    }).catchError((e) {
      print('Error al actualizar paquete: $e');
    });
  }

  //Funcion para agregar un paquete a un warehouse
  Future<void> addPaqueteToWarehouse(String paqueteId, String warehouseId) {
    return paquetes.doc(paqueteId).update({
      'WarehouseID': warehouseId
    }).then((_) {
      print('Paquete agregado al warehouse exitosamente');
    }).catchError((e) {
      print('Error al agregar paquete al warehouse: $e');
    });
  }

  //DELETE: eliminar paquete
  Future<void> deletePaquete(String paqueteId) {
    return paquetes.doc(paqueteId).delete().then((_) {
      print('Paquete eliminado exitosamente');
    }).catchError((e) {
      print('Error al eliminar paquete: $e');
    });
  }

  //CREATE: agregar nuevo cliente
  Future<void> addCliente(String nombre, String apellido, String numeroIdentidad, String email, String telefono, String direccion, String cuidad, String departamento, String pais) async {
    String clienteId = await _getNextClienteId(); // Obtener el siguiente cliente_id
    DateTime fecha = DateTime.now(); // Obtener la fecha y hora actual
    return clientes.add({
      'cliente_id': clienteId,
      'nombre': nombre,
      'apellido': apellido,
      'numero_identidad': numeroIdentidad,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'cuidad': cuidad,
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

  //READ: obtener todos los clientes
  Stream<QuerySnapshot> getClientes() {
    final clientestream = clientes.orderBy('fecha', descending: true).snapshots();
    return clientestream;
  }

  //UPDATE: actualizar cliente
  Future<void> updateCliente(String clienteId, String nombre, String apellido, String numeroIdentidad, String email, String telefono, String direccion, String cuidad, String departamento, String pais) {
    return clientes.doc(clienteId).update({
      'nombre': nombre,
      'apellido': apellido,
      'numero_identidad': numeroIdentidad,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'cuidad': cuidad,
      'departamento': departamento,
      'pais': 'Honduras'
    }).then((_) {
      print('Cliente actualizado exitosamente');
    }).catchError((e) {
      print('Error al actualizar cliente: $e');
    });
  }

  //DELETE: eliminar cliente
  Future<void> deleteCliente(String clienteId) {
    return clientes.doc(clienteId).delete().then((_) {
      print('Cliente eliminado exitosamente');
    }).catchError((e) {
      print('Error al eliminar cliente: $e');
    });
  }

  //CREATE: agregar nueva carga
  Future<void> addCarga(String entregaInicial, String entregaFinal, String estatusID, String fechaInicial, String fechaFinal, String modalidad, double peso, int piezas) async {
    String cargaId = await _getNextCargaId(); // Obtener el siguiente carga_id
    DateTime fecha = DateTime.now(); // Obtener la fecha y hora actual
    return cargas.add({
      'carga_id': cargaId,
      'entrega_inicial': entregaInicial,
      'entrega_final': entregaFinal,
      'estatus_id': estatusID,
      'fecha_inicial': fechaInicial,
      'fecha_final': fechaFinal,
      'modalidad': modalidad,
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

  //READ: obtener todas las cargas
  Stream<QuerySnapshot> getCargas() {
    final cargastream = cargas.orderBy('fecha', descending: true).snapshots();
    return cargastream;
  }

  //UPDATE: actualizar carga  
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

  //DELETE: eliminar carga
  Future<void> deleteCarga(String cargaId) {
    return cargas.doc(cargaId).delete().then((_) {
      print('Carga eliminada exitosamente');
    }).catchError((e) {
      print('Error al eliminar carga: $e');
    });
  }

  Future<double> _calculateTotalWeight(String warehouseID) async {
    QuerySnapshot querySnapshot = await paquetes.where('WarehouseID', isEqualTo: warehouseID).get();
    double totalWeight = 0;
    querySnapshot.docs.forEach((doc) {
      totalWeight += doc['Peso'];
    });
    return totalWeight;
  }

  Future<num> _calculateTotalPieces(String warehouseID) async {
     QuerySnapshot querySnapshot = await paquetes.where('WarehouseID', isEqualTo: warehouseID).get();
     num totalPieces = 0;
     querySnapshot.docs.forEach((doc) {
       totalPieces += doc['Piezas'];
     });
     return totalPieces;
   }

  //CREATE: agregar nuevo warehouse 
  Future<void> addWarehouse(String cargaID, String clienteID, String direccion, String estatusID, String modalidad, double pesoTotal, num piezas) async {
    String warehouseID = await _getNextWarehouseId(); // Obtener el siguiente warehouse_id
    DateTime fecha = DateTime.now(); // Obtener la fecha y hora actual
    return warehouse.add({
      'warehouse_id': warehouseID,
      'carga_id': cargaID,
      'cliente_id': clienteID,
      'direccion': direccion,
      'estatus_id': estatusID,
      'fecha': fecha,
      'modalidad': modalidad,
      'peso_total': '${await _calculateTotalWeight(warehouseID)} lbs', //calcular el peso total en el warehouse y sumarlo automáticamente en la creación del warehouse
      'piezas': '${await _calculateTotalPieces(warehouseID)} paquetes'//calcular el total de piezas en el warehouse y sumarlas automáticamente en la creación del warehouse
    }).then((_) {
      print('Warehouse agregado exitosamente');
    }).catchError((e) {
      print('Error al agregar warehouse: $e');
    });
  }

  // Función para obtener el siguiente warehouse_id
  Future<String> _getNextWarehouseId() async {
    QuerySnapshot querySnapshot = await warehouse.orderBy('warehouse_id', descending: true).limit(1).get();
    if (querySnapshot.docs.isNotEmpty) {
      String lastWarehouseId = querySnapshot.docs.first['warehouse_id'];
      int nextId = int.parse(lastWarehouseId.replaceAll('WRH', '')) + 1;
      return 'WRH$nextId';
    } else {
      return 'WRH1';
    }
  }

  //READ: obtener todos los warehouses
  Stream<QuerySnapshot> getWarehouses() {
    final warehousestream = warehouse.orderBy('fecha', descending: true).snapshots();
    return warehousestream;
  }

  //UPDATE: actualizar warehouse
  Future<void> updateWarehouse(String warehouseId, String cargaID, String clienteID, String direccion, String estatusID, String modalidad, double pesoTotal, int piezas) async {
    return warehouse.doc(warehouseId).update({
      'carga_id': cargaID,
      'cliente_id': clienteID,
      'direccion': direccion,
      'estatus_id': estatusID,
      'modalidad': modalidad,
      'piezas': piezas
    }).then((_) {
      print('Warehouse actualizado exitosamente');
    }).catchError((e) {
      print('Error al actualizar warehouse: $e');
    });
  }

  //DELETE: eliminar warehouse
  Future<void> deleteWarehouse(String warehouseId) {
    return warehouse.doc(warehouseId).delete().then((_) {
      print('Warehouse eliminado exitosamente');
    }).catchError((e) {
      print('Error al eliminar warehouse: $e');
    });
  }

  //READ: obtener todos los paquetes de un warehouse
  Stream<QuerySnapshot> getPaquetesWarehouse(String warehouseId) {
    final paquetesWarehouseStream = paquetes.where('WarehouseID', isEqualTo: warehouseId).snapshots();
    return paquetesWarehouseStream;
  }

  //READ: obtener todos los warehouses de un cliente
  Stream<QuerySnapshot> getWarehousesCliente(String clienteId) {
    final warehousesClienteStream = warehouse.where('cliente_id', isEqualTo: clienteId).snapshots();
    return warehousesClienteStream;
  }

  //READ: obtener todos los paquetes de un cliente
  Stream<QuerySnapshot> getPaquetesCliente(String clienteId) {
    final paquetesClienteStream = paquetes.where('cliente_id', isEqualTo: clienteId).snapshots();
    return paquetesClienteStream;
  }

  //READ: obtener todos los paquetes de una carga
  Stream<QuerySnapshot> getPaquetesCarga(String cargaId) {
    final paquetesCargaStream = paquetes.where('carga_id', isEqualTo: cargaId).snapshots();
    return paquetesCargaStream;
  }

  //READ: obtener todas las cargas de un cliente
  Stream<QuerySnapshot> getCargasCliente(String clienteId) {
    final cargasClienteStream = cargas.where('cliente_id', isEqualTo: clienteId).snapshots();
    return cargasClienteStream;
  }

  //READ: obtener todos los warehouse de una carga
  Stream<QuerySnapshot> getWarehousesCarga(String cargaId) {
    final warehousesCargaStream = warehouse.where('carga_id', isEqualTo: cargaId).snapshots();
    return warehousesCargaStream;
  }
}