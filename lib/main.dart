import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'UsuariosPantallas/mapa_librerias.dart';
import 'firebase_options.dart';

import 'login.dart';
import 'pantalla_admin.dart';
import 'pantalla_usuario.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginPage(),
        '/admin': (_) => const PantallaAdmin(),
        '/usuario': (_) => const PantallaUsuario(),
        '/mapa_librerias': (context) => const MapaLibrerias(),
      },
    );
  }
}
