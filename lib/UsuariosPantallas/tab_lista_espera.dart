import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modelo auxiliar para la vista de Lista de Espera
class ListaEsperaVista {
  final String idLibro; // Usaremos el ID del libro como ID de la solicitud
  final String tituloLibro;
  final String autorLibro;
  final String imagenLibro;
  final String nombreLibreria;
  final int posicionEnPila; // Tu posición actual en la pila (1 es el siguiente)
  final DateTime fechaSolicitud;

  ListaEsperaVista({
    required this.idLibro,
    required this.tituloLibro,
    required this.autorLibro,
    required this.imagenLibro,
    required this.nombreLibreria,
    required this.posicionEnPila,
    required this.fechaSolicitud,
  });
}

class TabListaEspera extends StatefulWidget {
  const TabListaEspera({super.key});

  @override
  State<TabListaEspera> createState() => _TabListaEsperaState();
}

class _TabListaEsperaState extends State<TabListaEspera> {
  List<ListaEsperaVista> _miListaEspera = [];
  bool _cargando = true;
  final Map<String, String> _libreriasCache = {};

  @override
  void initState() {
    super.initState();
    _cargarListaEsperaFirestore();
  }

  // ===================================
  //   1. Cargar Lista de Espera de Firestore
  // ===================================
  Future<void> _cargarListaEsperaFirestore() async {
    setState(() => _cargando = true);
    final emailUsuario = FirebaseAuth.instance.currentUser!.email;

    try {
      // 1. Obtener todos los libros (asumiendo que todos los libros tienen el array 'reservas')
      final query = await FirebaseFirestore.instance.collection('libros').get();

      List<ListaEsperaVista> temp = [];
      Set<String> libreriaIds = {};

      for (var doc in query.docs) {
        final data = doc.data();
        final List<dynamic> reservas = data['reservas'] ?? [];
        final idLibreria = data['idLibreria'] as String?;

        // 2. BUSCAR Y CALCULAR POSICIÓN
        // El array 'reservas' debe estar ordenado por fecha de reserva (más antigua primero).
        final indice = reservas.indexWhere((r) => r is Map && r['email'] == emailUsuario);

        if (indice != -1 && idLibreria != null) {
          // La posición en la pila es el índice + 1 (1-based index)
          final posicion = indice + 1;
          libreriaIds.add(idLibreria);

          final reservaEncontrada = reservas[indice] as Map<String, dynamic>;
          dynamic rawFecha = reservaEncontrada['fecha'];
          DateTime fechaSolicitud;

          if (rawFecha is String) {
            fechaSolicitud = DateTime.parse(rawFecha);
          } else if (rawFecha is Timestamp) {
            fechaSolicitud = rawFecha.toDate();
          } else {
            fechaSolicitud = DateTime.now();
          }

          temp.add(ListaEsperaVista(
            idLibro: doc.id,
            tituloLibro: data['nombre'] ?? 'Título Desconocido',
            autorLibro: data['autor'] ?? 'Autor Desconocido',
            imagenLibro: data['imagen'] ?? '',
            nombreLibreria: idLibreria, // Temporalmente el ID
            posicionEnPila: posicion,
            fechaSolicitud: fechaSolicitud,
          ));
        }
      }

      // 3. CARGAR DETALLES DE LIBRERÍA
      final List<Future<void>> fetchFutures = libreriaIds
          .where((id) => !_libreriasCache.containsKey(id))
          .map((id) async {
        final doc =
        await FirebaseFirestore.instance.collection("librerias").doc(id).get();
        _libreriasCache[id] = doc.data()?['nombre'] ?? 'Librería Desconocida';
      }).toList();

      await Future.wait(fetchFutures);

      // 4. ACTUALIZAR LAS RESERVAS CON EL NOMBRE REAL DE LA LIBRERÍA
      _miListaEspera = temp.map((reserva) {
        return ListaEsperaVista(
          idLibro: reserva.idLibro,
          tituloLibro: reserva.tituloLibro,
          autorLibro: reserva.autorLibro,
          imagenLibro: reserva.imagenLibro,
          posicionEnPila: reserva.posicionEnPila,
          fechaSolicitud: reserva.fechaSolicitud,
          nombreLibreria: _libreriasCache[reserva.nombreLibreria] ?? reserva.nombreLibreria,
        );
      }).toList();

    } catch (e) {
      print("Error al cargar la lista de espera: $e");
    }

    setState(() {
      _cargando = false;
    });
  }

  // ===================================
  //   2. Función para salir de la lista de espera (Firestore)
  // ===================================
  void _salirDeLaPila(String idLibro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Salir de la Lista de Espera"),
        content: const Text("¿Deseas retirar tu solicitud? Perderás tu lugar en la pila para este libro."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              final email = FirebaseAuth.instance.currentUser!.email;
              final docRef = FirebaseFirestore.instance.collection('libros').doc(idLibro);

              // 🛑 Se usa una transacción para asegurar la integridad
              await FirebaseFirestore.instance.runTransaction((transaction) async {
                final snapshot = await transaction.get(docRef);
                final List reservas = snapshot['reservas'] ?? [];

                // Remover la reserva del usuario por email
                reservas.removeWhere((r) => r['email'] == email);

                // Actualizar el documento
                transaction.update(docRef, {'reservas': reservas});
              });

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Has salido de la lista de espera")),
              );

              _cargarListaEsperaFirestore(); // Recargar la lista después de la eliminación
            },
            child: const Text("Sí, salir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🛑 Manejo del estado de carga
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    // ... (El resto del widget build es el mismo)
    if (_miListaEspera.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              "No estás en ninguna lista de espera",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Cuando un libro esté agotado, podrás unirte a la pila para recibirlo cuando se libere.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _miListaEspera.length,
      itemBuilder: (context, index) {
        final solicitud = _miListaEspera[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Encabezado visual de estado (Tope de pila o En espera)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                decoration: BoxDecoration(
                  color: solicitud.posicionEnPila == 1 ? Colors.green[50] : Colors.orange[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Icon(
                      solicitud.posicionEnPila == 1 ? Icons.check_circle_outline : Icons.access_time,
                      size: 16,
                      color: solicitud.posicionEnPila == 1 ? Colors.green[700] : Colors.orange[800],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      solicitud.posicionEnPila == 1
                          ? "¡Eres el siguiente! (Tope de la Pila)"
                          : "En espera - Posición: ${solicitud.posicionEnPila}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: solicitud.posicionEnPila == 1 ? Colors.green[800] : Colors.orange[900],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del Libro
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            solicitud.imagenLibro,
                            width: 70, height: 100, fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => Container(width: 70, height: 100, color: Colors.grey[300]),
                          ),
                        ),
                        // Icono de pila sobre la imagen
                        if (solicitud.posicionEnPila > 1)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20)
                            ),
                            child: const Icon(Icons.layers, color: Colors.white, size: 20),
                          )
                      ],
                    ),
                    const SizedBox(width: 15),

                    // Información
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            solicitud.tituloLibro,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(solicitud.autorLibro, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  solicitud.nombreLibreria,
                                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () => _salirDeLaPila(solicitud.idLibro),
                              icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.red),
                              label: const Text("Salir de la fila", style: TextStyle(color: Colors.red, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red, width: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                minimumSize: const Size(0, 30),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}