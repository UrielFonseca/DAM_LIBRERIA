import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modelo para mostrar reservas reales
class ReservaVista {
  final String idLibro;
  final String tituloLibro;
  final String autorLibro;
  final String imagenLibro;
  final String nombreLibreria;
  final String ubicacionLibreria;
  final DateTime fechaReserva;

  ReservaVista({
    required this.idLibro,
    required this.tituloLibro,
    required this.autorLibro,
    required this.imagenLibro,
    required this.nombreLibreria,
    required this.ubicacionLibreria,
    required this.fechaReserva,
  });
}

class TabReservas extends StatefulWidget {
  const TabReservas({super.key});

  @override
  State<TabReservas> createState() => _TabReservasState();
}

class _TabReservasState extends State<TabReservas> {
  List<ReservaVista> _misReservas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarReservas();
  }

  // ===============================
  //      Cargar reservas reales
  // ===============================
  Future<void> _cargarReservas() async {
    final emailUsuario = FirebaseAuth.instance.currentUser!.email;

    final query = await FirebaseFirestore.instance.collection('libros').get();

    List<ReservaVista> temp = [];

    for (var doc in query.docs) {
      final data = doc.data();
      final reservas = data['reservas'] ?? [];

      // ¿El usuario reservó este libro?
      final item = reservas.firstWhere(
            (r) => r['email'] == emailUsuario,
        orElse: () => null,
      );

      if (item != null) {
        temp.add(ReservaVista(
          idLibro: doc.id,
          tituloLibro: data['nombre'],
          autorLibro: data['autor'],
          imagenLibro: data['imagen'],
          nombreLibreria: data['idLibreria'],
          ubicacionLibreria: data['ubicacion'] ?? "Sin ubicación",
          fechaReserva: (item['fecha'] as Timestamp).toDate(),
        ));
      }
    }

    setState(() {
      _misReservas = temp;
      _cargando = false;
    });
  }

  // ===============================
  //      Cancelar reserva real
  // ===============================
  void _cancelarReserva(String idLibro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancelar Reserva"),
        content: const Text("¿Deseas cancelar esta reserva?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              final email = FirebaseAuth.instance.currentUser!.email;

              final docRef =
              FirebaseFirestore.instance.collection('libros').doc(idLibro);

              final doc = await docRef.get();
              List reservas = doc['reservas'] ?? [];

              reservas.removeWhere((r) => r['email'] == email);

              await docRef.update({'reservas': reservas});

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Reserva cancelada")),
              );

              _cargarReservas(); // recargar lista
            },
            child: const Text("Sí, cancelar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_misReservas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              "No tienes reservas activas",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ve al Catálogo para reservar")),
                );
              },
              child: const Text("Ir a Catálogo"),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _misReservas.length,
      itemBuilder: (context, index) {
        final reserva = _misReservas[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del Libro
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    reserva.imagenLibro,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book),
                    ),
                  ),
                ),
                const SizedBox(width: 15),

                // Información del libro integrado
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titulo + opción cancelar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              reserva.tituloLibro,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _cancelarReserva(reserva.idLibro),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.cancel_outlined,
                                  color: Colors.red, size: 20),
                            ),
                          )
                        ],
                      ),

                      Text(
                        reserva.autorLibro,
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 10),

                      // Librería
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.store,
                                    size: 14, color: Colors.blue),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    reserva.nombreLibreria,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.blue),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reserva.ubicacionLibreria,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.blue[800]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Fecha
                      Text(
                        "Reservado el ${reserva.fechaReserva.day}/${reserva.fechaReserva.month}/${reserva.fechaReserva.year}",
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
