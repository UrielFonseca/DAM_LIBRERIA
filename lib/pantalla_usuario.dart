import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'UsuariosPantallas/tab_libros.dart';
import 'UsuariosPantallas/tab_reservas.dart';
import 'UsuariosPantallas/tab_lista_espera.dart';
import 'UsuariosPantallas/mapa_librerias.dart';

class PantallaUsuario extends StatefulWidget {
  const PantallaUsuario({super.key});

  @override
  State<PantallaUsuario> createState() => _PantallaUsuarioState();
}

class _PantallaUsuarioState extends State<PantallaUsuario> {
  int _selectedIndex = 0;
  String _titulo = "Catálogo de Libros";

  // Lista de las vistas
  final List<Widget> _vistas = [
    const TabLibros(),      // Índice 0
    const TabReservas(),    // Índice 1
    const TabListaEspera(), // Índice 2
    const MapaLibrerias(),        // Índice 3
  ];

  void _cambiarVista(int index, String titulo) {
    setState(() {
      _selectedIndex = index;
      _titulo = titulo;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulo),
        backgroundColor: Colors.blue,
      ),

      // MENÚ LATERAL
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_pin, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Menú Usuario",
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            //Libros
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text("Catálogo de Libros"),
              selected: _selectedIndex == 0,
              onTap: () => _cambiarVista(0, "Catálogo de Libros"),
            ),
            //Reservas
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text("Mis Reservas"),
              selected: _selectedIndex == 1,
              onTap: () => _cambiarVista(1, "Mis Reservas"),
            ),
            //Lista de Espera
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text("Lista de Espera"),
              selected: _selectedIndex == 2,
              onTap: () => _cambiarVista(2, "Lista de Espera"),
            ),
            //Mapa
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Mapa de Librerías"),
              selected: _selectedIndex == 3,
              onTap: () => _cambiarVista(3, "Mapa de Librerías"),
            ),
            const Divider(),
            //Logout
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
          ],
        ),
      ),
      body: _vistas[_selectedIndex],
    );
  }
}
