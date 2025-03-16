import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendEmailPage extends StatelessWidget {
  const SendEmailPage({super.key});

  Future<void> sendEmailToGerente() async {
    try {
      // Obtener el correo del gerente
      DocumentSnapshot gerenteSnapshot = await FirebaseFirestore.instance
          .collection('Gerencia')
          .doc('GR1')
          .get();
      String gerenteEmail = gerenteSnapshot['email'] ?? 'cariasangel60@gmail.com';

      // Obtener el estado de los paquetes
      QuerySnapshot paquetesSnapshot =
          await FirebaseFirestore.instance.collection('Paquetes').get();

      List<Map<String, dynamic>> paquetesData = [];
      for (var doc in paquetesSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String estatusId = data['EstatusID'] ?? 'Desconocido';
          DocumentSnapshot estadoSnapshot = await FirebaseFirestore.instance
              .collection('Estatus')
              .doc(estatusId)
              .get();
          String estadoNombre = estadoSnapshot.exists ? estadoSnapshot['Nombre'] : 'Desconocido';
          data['Nombre'] = estadoNombre;
          paquetesData.add(data);
        } catch (e) {
          print('Error al obtener datos del paquete: $e');
          paquetesData.add({'paquete_id': 'Desconocido', 'Nombre': 'Desconocido'});
        }
      }

      // Crear el contenido del correo en HTML
      String emailContent = '''
      <html>
      <head>
        <style>
          body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            color: #333;
          }
          .container {
            width: 80%;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
          }
          .header {
            text-align: center;
            padding: 10px 0;
          }
          .header img {
            width: 150px;
          }
          .header h1 {
            color: #ff6600;
          }
          .content {
            margin: 20px 0;
          }
          .content h2 {
            color: #0066cc;
          }
          .content p {
            line-height: 1.6;
          }
          .footer {
            text-align: center;
            padding: 10px 0;
            color: #777;
          }
          table {
            width: 100%;
            border-collapse: collapse;
          }
          table, th, td {
            border: 1px solid #ddd;
          }
          th, td {
            padding: 8px;
            text-align: left;
          }
          th {
            background-color: #ff6600;
            color: white;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <img src="https://i.imgur.com/8cYBfkm.jpeg" alt="Premium Logistics Cargo">
            <h1>Estado de los Paquetes</h1>
          </div>
          <div class="content">
            <h2>Estimado Gerente,</h2>
            <p>A continuación se muestra el estado de los paquetes:</p>
            <table>
              <tr>
                <th>Paquete ID</th>
                <th>Estado</th>
              </tr>
      ''';

      for (var paquete in paquetesData) {
        emailContent += '''
              <tr>
                <td>${paquete['paquete_id'] ?? 'Desconocido'}</td>
                <td>${paquete['Nombre'] ?? 'Desconocido'}</td>
              </tr>
        ''';
      }

      emailContent += '''
            </table>
          </div>
          <div class="footer">
            <p>PREMIUM LOGISTICS CARGO</p>
          </div>
        </div>
      </body>
      </html>
      ''';

      // Enviar el correo utilizando EmailJS
      const serviceId = 'service_u5n9hww';
      const templateId = 'contact_form';
      const userId = '67JFCnhnFGGRXFSJD';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_email': gerenteEmail,
            'subject': 'Estado de los Paquetes',
            'html': emailContent,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Correo enviado al gerente');
      } else {
        print('Error al enviar correo al gerente: ${response.body}');
      }
    } catch (e) {
      print('Error al enviar correo al gerente: $e');
    }
  }

  Future<void> sendEmailToClientes() async {
    try {
      // Obtener el estado de los paquetes
      QuerySnapshot paquetesSnapshot =
          await FirebaseFirestore.instance.collection('Paquetes').get();

      for (var doc in paquetesSnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String estatusId = data['EstatusID'] ?? 'Desconocido';
          String paqueteId = data['paquete_id'] ?? 'Desconocido';
          DocumentSnapshot estadoSnapshot = await FirebaseFirestore.instance
              .collection('Estatus')
              .doc(estatusId)
              .get();
          String estadoNombre = estadoSnapshot.exists ? estadoSnapshot['Nombre'] : 'Desconocido';

          // Obtener el warehouseID y luego el cliente_id
          String warehouseId = data['warehouseID'] ?? 'Desconocido';
          DocumentSnapshot warehouseSnapshot = await FirebaseFirestore.instance
              .collection('Warehouse')
              .doc(warehouseId)
              .get();
          String clienteId = warehouseSnapshot.exists ? warehouseSnapshot['cliente_id'] : 'Desconocido';

          // Obtener el correo y nombre del cliente
          DocumentSnapshot clienteSnapshot = await FirebaseFirestore.instance
              .collection('Clientes')
              .doc(clienteId)
              .get();
          String clienteEmail = clienteSnapshot.exists ? clienteSnapshot['email'] : 'desconocido@example.com';
          String clienteNombre = clienteSnapshot.exists ? clienteSnapshot['nombre'] : 'Cliente';

          // Validar el correo electrónico
          if (!clienteEmail.contains('@gmail.com')) {
            clienteEmail = 'cariasangel60@gmail.com';
          }

          // Crear el contenido del correo
          String emailContent = 
              'El estado de su paquete $paqueteId es:\n\n'
              '$estadoNombre\n\n';

          // Enviar el correo utilizando EmailJS
          const serviceId = 'service_u5n9hww';
          const templateId = 'estado_paquetes';
          const userId = '67JFCnhnFGGRXFSJD';

          final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'service_id': serviceId,
              'template_id': templateId,
              'user_id': userId,
              'template_params': {
                'to_email': clienteEmail,
                'ClienteNombre': clienteNombre,
                'paqueteID': paqueteId,
                'message': emailContent,
              },
            }),
          );

          if (response.statusCode == 200) {
            print('Correo enviado al cliente $clienteEmail');
          } else {
            print('Error al enviar correo al cliente $clienteEmail: ${response.body}');
          }
        } catch (e) {
          print('Error al obtener datos del paquete o enviar correo: $e');
        }
      }
    } catch (e) {
      print('Error al enviar correos a los clientes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de los Paquetes'),
        backgroundColor: Colors.blue.shade900,
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  minimumSize: const Size(160, 160),
                  elevation: 5,
                ),
                onPressed: () {
                  _showConfirmationDialog(context, '¿Está seguro de enviar el correo al gerente?', sendEmailToGerente);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.email, size: 50),
                    SizedBox(height: 10),
                    Text(
                      'Enviar Correo a Gerente',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  minimumSize: const Size(160, 160),
                  elevation: 5,
                ),
                onPressed: () {
                  _showConfirmationDialog(context, '¿Está seguro de enviar el correo a los clientes?', sendEmailToClientes);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.email, size: 50),
                    SizedBox(height: 10),
                    Text(
                      'Enviar Correo a Clientes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context, String message, Function onConfirm) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
