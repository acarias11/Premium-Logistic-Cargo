import 'package:flutter/material.dart';
import 'package:plc_pruebas/pages/reports/clientes_eliminar_page.dart';
import 'package:plc_pruebas/pages/reports/clientes_peso_page.dart';
import 'package:plc_pruebas/pages/reports/grafica_activos&inactivos_page.dart';
import 'package:plc_pruebas/pages/reports/grafica_casilleros_mensuales.dart';
import 'package:plc_pruebas/pages/reports/grafica_prom_page.dart'; // Ensure this file contains the GraficaPromPage class
import 'package:plc_pruebas/pages/reports/prom_peso.dart';
import 'package:plc_pruebas/pages/reports/quejas_page.dart';
import 'package:plc_pruebas/pages/reports/send_email.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';
//import 'package:plc_pruebas/pages/reports/rcasilleros_page.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  _ReportesPageState createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 50, 110),
      ),
      drawer: Sidebar(selectedIndex: 5, controller: _sidebarXController),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 10, 50, 110), const Color.fromARGB(255, 10, 50, 110)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Reportes',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Texto en blanco
                ),
              ),
              SizedBox(height: 20),
              // First Row of Buttons
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStyledButton(context, 'Casilleros Mensuales', Icons.calendar_today, GraficaCasillerosMensuales()),
                    const SizedBox(width: 30),
                    _buildStyledButton(context, 'Reporte Gráfico de Modalidad', Icons.bar_chart, GraficaPromPage()),
                    const SizedBox(width: 30),
                    _buildStyledButton(context, 'Email Estados', Icons.email, SendEmailPage()),
                    const SizedBox(width: 30),
                    _buildStyledButton(context, 'Usuarios Activos e Inactivos', Icons.people, GraficaActivosInactivosPage()),
                  ],
                ),
              const SizedBox(height: 30),
              // Second Row of Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStyledButton(context, 'Registro de Quejas', Icons.report_problem, QuejasPage()),
                    const SizedBox(width: 30),
                    _buildStyledButton(context, 'Promedios', Icons.show_chart, PromPesoPage()),
                    const SizedBox(width: 30),
                    _buildStyledButton(context, 'Clientes Frecuentes', Icons.star, ClientesPesoPage()),
                    const SizedBox(width: 30),
                   _buildStyledButton(context, 'Clientes para Eliminar', Icons.delete, ClientesEliminarPage()),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledButton(BuildContext context, String title, IconData icon, Widget? page) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 9, 77, 205), // Fondo azul oscuro
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