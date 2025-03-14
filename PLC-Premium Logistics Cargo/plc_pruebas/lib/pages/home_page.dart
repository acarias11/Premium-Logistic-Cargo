import 'package:flutter/material.dart';
import 'package:plc_pruebas/pages/reportes_page.dart';
import 'package:plc_pruebas/pages/reports/quejas_page.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:plc_pruebas/pages/clientes_page.dart';
import 'package:plc_pruebas/pages/paquetes_page.dart';
import 'package:plc_pruebas/pages/warehouse_page.dart';
import 'package:plc_pruebas/pages/cargas_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar Firebase Auth

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: const Text(
          'Premium Logistics Cargo',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Lógica para cerrar sesión con Firebase Auth
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      drawer: Sidebar(
        selectedIndex: 0,
        controller: _sidebarXController,
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
              // Logo
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/logo_PLC.jpg', // imagen
                  height: 200,
                  width: 200,
                ),
              ),
              const SizedBox(height: 20),
              // Buttons Section
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildStyledButton(context, 'Cargas', Icons.local_shipping,
                      const CargasPage()),
                  _buildStyledButton(context, 'Warehouse', Icons.warehouse,
                      const WarehousePage()),
                  _buildStyledButton(context, 'Paquetes', Icons.inventory_2,
                      const PaquetesPage()),
                  _buildStyledButton(
                      context, 'Clientes', Icons.person, const ClientesPage()),
                  _buildStyledButton(
                      context, 'Reportes', Icons.insert_chart, ReportesPage()),
                   _buildStyledButton(
                      context, 'Quejas', Icons.report_problem, QuejasPage()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledButton(
      BuildContext context, String title, IconData icon, Widget? page) {
    return ElevatedButton(
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
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        } else {
           Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const ReportesPage()),
           );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
