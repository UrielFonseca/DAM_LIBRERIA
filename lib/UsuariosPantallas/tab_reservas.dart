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
  // Ubicación se puede obtener de la librería (asumiendo que idLibreria es el ID del documento)
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

  // Cache para los detalles de las librerías
  final Map<String, Map<String, String>> _libreriasCache = {};

  @override
  void initState() {
    super.initState();
    _cargarReservas();
  }

  // ===============================
//      Cargar reservas reales (CORREGIDA)
// ===============================
  Future<void> _cargarReservas() async {
    setState(() => _cargando = true);
    final emailUsuario = FirebaseAuth.instance.currentUser!.email;

    try {
      final query = await FirebaseFirestore.instance.collection('libros').get();

      List<ReservaVista> temp = [];
      Set<String> libreriaIds = {};

      // 1. ITERAR LIBROS, ENCONTRAR RESERVAS Y OBTENER IDs DE LIBRERÍA
      for (var doc in query.docs) {
        final data = doc.data();
        // Aseguramos que 'reservas' es una lista
        final List<dynamic> reservas = data['reservas'] ?? [];
        final idLibreria = data['idLibreria'] as String?;

        // ✅ CORRECCIÓN: Usamos .where para filtrar la reserva y .isNotEmpty para verificar su existencia
        final reservaUsuario = reservas
            .where((r) => r is Map && r['email'] == emailUsuario)
            .toList();

        if (reservaUsuario.isNotEmpty && idLibreria != null) {
          // Tomamos el primer (y único) elemento
          final reservaEncontrada = reservaUsuario.first as Map<String, dynamic>;
          libreriaIds.add(idLibreria);

          // Obtener la fecha, maneja String o Timestamp.
          dynamic rawFecha = reservaEncontrada['fecha'];
          DateTime fechaReserva;

          if (rawFecha is String) {
            fechaReserva = DateTime.parse(rawFecha);
          } else if (rawFecha is Timestamp) {
            fechaReserva = rawFecha.toDate();
          } else {
            fechaReserva = DateTime.now();
          }

          temp.add(ReservaVista(
            idLibro: doc.id,
            tituloLibro: data['nombre'] ?? 'Título Desconocido',
            autorLibro: data['autor'] ?? 'Autor Desconocido',
            imagenLibro: data['imagen'] ?? '',
            nombreLibreria: idLibreria,
            ubicacionLibreria: "Cargando...",
            fechaReserva: fechaReserva,
          ));
        }
      }

      // 2. CARGAR DETALLES DE LIBRERÍA
      final List<Future<void>> fetchFutures = libreriaIds
          .where((id) => !_libreriasCache.containsKey(id))
          .map((id) async {
        final doc =
        await FirebaseFirestore.instance.collection("librerias").doc(id).get();
        final libData = doc.data();
        if (libData != null) {
          _libreriasCache[id] = {
            'nombre': libData['nombre'] ?? 'Librería Desconocida',
            'ubicacion': libData['ubicacion'] ?? 'Sin Ubicación'
          };
        } else {
          _libreriasCache[id] = {
            'nombre': 'Librería Desconocida',
            'ubicacion': 'Sin Ubicación'
          };
        }
      }).toList();

      await Future.wait(fetchFutures);

      // 3. ACTUALIZAR LAS RESERVAS CON LOS DETALLES DE LA LIBRERÍA
      _misReservas = temp.map((reserva) {
        final detalles = _libreriasCache[reserva.nombreLibreria];
        return ReservaVista(
          idLibro: reserva.idLibro,
          tituloLibro: reserva.tituloLibro,
          autorLibro: reserva.autorLibro,
          imagenLibro: reserva.imagenLibro,
          fechaReserva: reserva.fechaReserva,
          nombreLibreria: detalles?['nombre'] ?? reserva.nombreLibreria,
          ubicacionLibreria: detalles?['ubicacion'] ?? "Sin Ubicación",
        );
      }).toList();

    } catch (e) {
      print("Error al cargar reservas: $e");
      // Puedes agregar manejo de errores visual aquí si lo deseas
    }

    setState(() {
      _cargando = false;
    });
  }

  // ... (El resto de _cancelarReserva y build es el mismo)

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
                // Aquí deberías navegar al catálogo de libros (TabLibros)
                // Dependiendo de tu implementación de tabs, esto podría ser:
                // DefaultTabController.of(context)?.animateTo(indice_del_catalogo);
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
