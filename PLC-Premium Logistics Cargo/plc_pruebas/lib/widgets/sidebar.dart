//importas todas las pages para las rutas
import 'package:plc_pruebas/pages/home_page.dart';
import 'package:plc_pruebas/pages/paquetes_page.dart';
//import 'package:plc_pruebas/pages/usuarios_page.dart';
import 'package:plc_pruebas/pages/warehouse_page.dart';
import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';

//rehacerlo integrando la dependencia sidebarx

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final SidebarXController controller;
  
  const Sidebar({
    super.key, 
    required this.selectedIndex, 
    required this.controller
    });   
  
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150, //Para que no tape la pantalla
      child: SidebarX(
        controller: controller,
        theme: SidebarXTheme(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E48),
            borderRadius: BorderRadius.circular(20),
          ),
          hoverColor: const Color(0xFF464667),
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
          border: Border.all(color: const Color(0xFF2E2E48)),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF5F5FA7).withOpacity(0.6).withOpacity(0.37),
          ),
          gradient: const LinearGradient(
            colors: [Color(0xFF3E3E61), Color(0xFF2E2E48)],
          ),
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
          color: const Color(0xFF2E2E48),
          borderRadius: BorderRadius.circular(20),

        )
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
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          SidebarXItem(
            icon: Icons.store,
            label: 'Warehouse',
            onTap: () {
              debugPrint('Warehouse');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => WarehousePage()),
              );
            },
          ),
          SidebarXItem(
            icon: Icons.shopping_cart,
            label: 'Paquetes',
            onTap: () {
              debugPrint('Paquetes');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => PaquetesPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}