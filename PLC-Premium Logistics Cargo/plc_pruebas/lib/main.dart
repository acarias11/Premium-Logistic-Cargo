import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:plc_pruebas/firebase_options.dart';
import 'package:plc_pruebas/pages/cargaPage.dart';
import 'package:plc_pruebas/pages/cargas_page.dart';
import 'package:plc_pruebas/pages/clientes_page.dart';
import 'package:plc_pruebas/pages/home_page.dart';
import 'package:plc_pruebas/pages/paquetes_page.dart';
import 'package:plc_pruebas/pages/reports/quejas_page.dart';
import 'package:plc_pruebas/pages/reports/send_email.dart';
import 'package:plc_pruebas/pages/signIn_page.dart';
import 'package:plc_pruebas/pages/signUp_page.dart';
import 'package:plc_pruebas/pages/warehouse_page.dart';
import 'package:plc_pruebas/pages/prueba_sidebar.dart';
import 'package:plc_pruebas/pages/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:plc_pruebas/pages/provider/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/signIn',
      routes: {
        '/': (BuildContext context) => SignInPage(),
        '/home': (BuildContext context) => HomePage(),
        '/warehouse': (BuildContext context) => const WarehousePage(),
        '/cargas': (BuildContext context) => const CargasPage(),
        '/paquetes': (BuildContext context) => const PaquetesPage(),
        '/WarehousePage': (BuildContext context) => const WarehousePage(),
        '/Quejas': (BuildContext context) => const QuejasPage(),
        '/Clientes': (BuildContext context) => const ClientesPage(),
        '/prueba_sidebar': (BuildContext context) => PruebaSidebar(),
        '/cargoPage': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return CargoPage(cargaId: args ?? '');
        },
        '/SendEmailPage': (BuildContext context) => const SendEmailPage(),
        '/signIn': (BuildContext context) => SignInPage(),
        '/signUp': (BuildContext context) => const SignUpPage(),
        '/splash': (context) => SplashPage(),
      },
    );
  }
}