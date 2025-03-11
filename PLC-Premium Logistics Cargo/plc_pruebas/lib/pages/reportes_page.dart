import 'package:flutter/material.dart';
import 'package:plc_pruebas/pages/reports/clientes_eliminar_page.dart';
import 'package:plc_pruebas/pages/reports/clientes_peso_page.dart';
import 'package:plc_pruebas/pages/reports/grafica_activos&inactivos_page.dart';
import 'package:plc_pruebas/pages/reports/grafica_casilleros_mensuales.dart';
import 'package:plc_pruebas/pages/reports/grafica_prom_page.dart';
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
        title: const Text('Reportes'),
        backgroundColor: Colors.blue.shade900,
      ),
      drawer: Sidebar(selectedIndex: 5, controller: _sidebarXController),
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
              // First Row of Buttons
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildStyledButton(context, 'Casilleros Mensuales', Icons.calendar_today, GraficaCasillerosMensuales()),
                  _buildStyledButton(context, 'Reporte Gráfico de Modalidad', Icons.bar_chart, GraficaPromPage()),
                  _buildStyledButton(context, 'Email Estados', Icons.email, SendEmailPage()),
                  _buildStyledButton(context, 'Usuarios Activos e Inactivos', Icons.people, GraficaActivosInactivosPage()),
                ],
              ),
              const SizedBox(height: 20),
              // Second Row of Buttons
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildStyledButton(context, 'Registro de Quejas', Icons.report_problem, QuejasPage()),
                  _buildStyledButton(context, 'Promedios', Icons.show_chart, PromPesoPage()),
                  _buildStyledButton(context, 'Clientes Frecuentes', Icons.star, ClientesPesoPage()),
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
          // Comentado porque aún no hay funcionalidad
          // [Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => page),
          // );
          // ]
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}