import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  //get collection reference
  final CollectionReference paquetes =
   FirebaseFirestore.instance.collection('paquetes');

  //CREATE: agregar nuevo paquete
  Future<void> addPaquete(String nombre, String warehouseId, double peso, String tipo, String modalidadEnvio) {
    var uuid = const Uuid();
    String paqueteId = uuid.v4(); // Generar un paquete_id único
    //Generar un tracking unico
    String tracking = uuid.v4();
    DateTime fecha = DateTime.now(); // Obtener la fecha y hora actual

    return paquetes.add({
      'paquete_id': paqueteId,
      'nombre': nombre,
      'fecha': fecha,
      'warehouse_id': warehouseId,
      'tracking': tracking,
      'peso': peso,
      'tipo': tipo,
      'modalidad_envio': modalidadEnvio
    }).then((_) {
      print('Paquete agregado exitosamente');
    }).catchError((e) {
      print('Error al agregar paquete: $e');
    });
  }

  //READ: obtener todos los paquetes
  Stream<QuerySnapshot> getPaquetes() {
    final paquestream =
    paquetes.orderBy('fecha', descending: true).snapshots();
    return paquestream;
  }

  //UPDATE: actualizar paquete
  Future<void> updatePaquete(String paqueteId, String nombre, String warehouseId, double peso, String tipo, String modalidadEnvio) {
    return paquetes.doc(paqueteId).update({
      'nombre': nombre,
      'warehouse_id': warehouseId,
      'peso': peso,
      'tipo': tipo,
      'modalidad_envio': modalidadEnvio
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