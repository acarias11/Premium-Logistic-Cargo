import 'package:flutter/material.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:plc_pruebas/pages/clientes_page.dart';
import 'package:plc_pruebas/pages/paquetes_page.dart';
import 'package:plc_pruebas/pages/warehouse_page.dart';
import 'package:plc_pruebas/pages/cargas_page.dart';

import '../widgets/sidebar.dart';
import 'cargas_page.dart';
import 'paquetes_page.dart';
import 'warehouse_page.dart';

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
                  'lib/assets/PLC.png', // imagen
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
                  _buildStyledButton(context, 'Paquetes', Icons.local_shipping,
                      const PaquetesPage()),
                  _buildStyledButton(context, 'Warehouse', Icons.warehouse,
                      const WarehousePage()),
                  _buildStyledButton(context, 'Cargas', Icons.airplane_ticket,
                      const CargasPage()),
                  _buildStyledButton(
                      context, 'Cliente', Icons.person, const ClientesPage()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledButton(
      BuildContext context, String title, IconData icon, Widget page) {
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
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
