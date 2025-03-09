//pagina para hacer pruebas del sidebar
import 'package:flutter/material.dart';
//importar el sidebar
import 'package:plc_pruebas/widgets/sidebar.dart';
import 'package:sidebarx/sidebarx.dart';


class PruebaSidebar extends StatelessWidget {
//agregar el controlador del sidebar
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 0);

  PruebaSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pruebas del Sidebar'),
      ),
      drawer: Sidebar(
        selectedIndex: 0,
        controller: _sidebarXController,
      ),
      body: const Center(
        child: Text('Welcome to the Home Page!'),
      ),
    );
  }
}
