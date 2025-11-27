import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqlite/UsuariosPantallas/mapa_librerias.dart';


class PantallaUsuario extends StatelessWidget {
  const PantallaUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio de Usuario"),
        backgroundColor: Colors.blue,
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  "Usuario",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Ver Librerías en el Mapa"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.book),
              title: const Text("Reservar Libros"),
              onTap: () {},
            ),

            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Ver Librerías en el Mapa"),
              onTap: () {
                Navigator.pushNamed(context, '/mapa_librerias');
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Cerrar sesión"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),

      body: const Center(
        child: Text(
          "Bienvenido Usuario",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
