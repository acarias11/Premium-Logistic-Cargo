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
import 'package:provider/provider.dart';
import 'package:plc_pruebas/pages/provider/theme_provider.dart';

class HomePage extends StatelessWidget {

  HomePage({super.key});

  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 0);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final _isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Color.fromARGB(255, 0, 0, 0) : Color.fromARGB(255, 10, 50, 110),
        title: const Text(
          'Premium Logistics Cargo',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // Botón para alternar entre modo claro y oscuro
          IconButton(
            icon: Icon(themeProvider.isDarkMode
                ? Icons.nightlight_round
                : Icons.wb_sunny),
            onPressed: () {
              themeProvider.toggleTheme(); // Alterna el estado global del tema
            },
            color: Colors.white,
          ),
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
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
            colors: _isDarkMode ? [Color.fromARGB(255, 0, 0, 0), Color.fromARGB(255, 0, 0, 0)] : [Color.fromARGB(255, 10, 50, 110), const Color.fromARGB(255, 10, 50, 110)],
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'assets/logo_PLC.jpg', // imagen
                    height: 200,
                    width: 200,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Sección de botones
              Wrap(
                spacing: 30,
                runSpacing: 30,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final _isDarkMode = themeProvider.isDarkMode;
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: _isDarkMode ? Color.fromRGBO(30, 30, 30, 1) : const Color.fromARGB(255, 9, 77, 205), // Fondo azul oscuro
        borderRadius: BorderRadius.circular(15.0), // Bordes redondeados
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Sombra ligera
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15.0),
          onTap: () {
            if (page != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2), // Fondo translúcido
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.orange.shade400, // Icono en naranja
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Texto en blanco
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
