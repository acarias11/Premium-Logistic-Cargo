import 'package:plc_pruebas/pages/home_page.dart';
import 'package:plc_pruebas/pages/paquetes_page.dart';
import 'package:plc_pruebas/pages/reports/quejas_page.dart';
import 'package:plc_pruebas/pages/warehouse_page.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:plc_pruebas/pages/cargas_page.dart';
import 'package:plc_pruebas/pages/clientes_page.dart';
import 'package:plc_pruebas/pages/reportes_page.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final SidebarXController controller;

  const Sidebar(
      {super.key, required this.selectedIndex, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150, //Para que no tape la pantalla
      child: SidebarX(
        controller: controller,
        theme: SidebarXTheme(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: BorderRadius.circular(20),
          ),
          hoverColor: Colors.orange.shade700,
          textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          selectedTextStyle: const TextStyle(color: Colors.white),
          hoverTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          itemTextPadding: const EdgeInsets.only(left: 30),
          selectedItemTextPadding: const EdgeInsets.only(left: 30),
          itemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade900),
          ),
          selectedItemDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.orange.shade700.withOpacity(0.6).withOpacity(0.37),
            ),
            color: Colors.orange.shade700,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 30,
              )
            ],
          ),
          iconTheme: IconThemeData(
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          selectedIconTheme: const IconThemeData(
            color: Colors.white,
            size: 20,
          ),
        ),
        extendedTheme: SidebarXTheme(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          width: 950,
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        //Aqui se agregan los items del sidebar
        items: [
          SidebarXItem(
            icon: Icons.home,
            label: 'Home',
            onTap: () {
              debugPrint('Home');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          SidebarXItem(
            icon: Icons.local_shipping,
            label: 'Cargas',
            onTap: () {
              debugPrint('Cargas');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CargasPage()),
              );
            },
          ),
          SidebarXItem(
            icon: Icons.warehouse,
            label: 'Warehouse',
            onTap: () {
              debugPrint('Warehouse');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WarehousePage()),
              );
            },
          ),
          SidebarXItem(
            icon: Icons.inventory_2,
            label: 'Paquetes',
            onTap: () {
              debugPrint('Paquetes');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PaquetesPage()),
              );
            },
          ),
          SidebarXItem(
            icon: Icons.person,
            label: 'Clientes',
            onTap: () {
              debugPrint('Clientes');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ClientesPage()),
              );
            },
          ),
          SidebarXItem(
            icon: Icons.insert_chart,
            label: 'Reportes',
            onTap: () {
              debugPrint('Reportes');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ReportesPage()),
              );
            },
          ),
          SidebarXItem(
            icon: Icons.report_problem,
            label: 'Quejas',
            onTap: () {
              debugPrint('Quejas');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const QuejasPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}