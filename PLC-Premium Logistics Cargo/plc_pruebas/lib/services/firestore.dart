import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  //get collection reference
  final CollectionReference paquetes = FirebaseFirestore.instance.collection('Paquetes');

  //CREATE: agregar nuevo paquete
  Future<void> addPaquete(String trakingNumber, String warehouseId, String direccion, double peso, String tipo, String modalidadEnvio) async {
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
      'EstatusID': 'EST1'
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
  Future<void> updatePaquete(String paqueteId, String trakingNumber, String warehouseId, String direccion, double peso, String tipo, String modalidadEnvio) {
    return paquetes.doc(paqueteId).update({
      'TrakingNumber': trakingNumber,
      'WarehouseID': warehouseId,
      'Peso': peso,
      'Tipo': tipo,
      'Modalidad': modalidadEnvio,
      'Direccion': direccion
    }).then((_) {
      print('Paquete actualizado exitosamente');
    }).catchError((e) {
      print('Error al actualizar paquete: $e');
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
}