import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:plc_pruebas/widgets/sidebar.dart';


class QuejasPage extends StatefulWidget {
  const QuejasPage({super.key});

  @override
  _QuejasPageState createState() => _QuejasPageState();
}

class _QuejasPageState extends State<QuejasPage> {
  final SidebarXController _sidebarXController =
      SidebarXController(selectedIndex: 6);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quejas'),
      ),
      drawer: Sidebar(selectedIndex: 6, controller: _sidebarXController),
      body: const Center(
        child: Text('Quejas Page'),
      ),
    );
  }
}
