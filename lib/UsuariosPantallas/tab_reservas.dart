import 'package:flutter/material.dart';

// Modelo auxiliar para la vista de reservas (Simula Join de Reserva + Libro + Librería)
class ReservaVista {
  final String idReserva;
  final String tituloLibro;
  final String autorLibro;
  final String imagenLibro;
  final String nombreLibreria;
  final String ubicacionLibreria;
  final DateTime fechaReserva;
  final String estado; // Ejemplo: "Listo para recoger", "Pendiente"

  ReservaVista({
    required this.idReserva,
    required this.tituloLibro,
    required this.autorLibro,
    required this.imagenLibro,
    required this.nombreLibreria,
    required this.ubicacionLibreria,
    required this.fechaReserva,
    this.estado = "Listo para recoger",
  });
}

class TabReservas extends StatefulWidget {
  const TabReservas({super.key});

  @override
  State<TabReservas> createState() => _TabReservasState();
}

class _TabReservasState extends State<TabReservas> {
  // DATOS DE PRUEBA (Dummies)
  List<ReservaVista> _misReservas = [
    ReservaVista(
      idReserva: "res001",
      tituloLibro: "El Principito",
      autorLibro: "Antoine de Saint-Exupéry",
      imagenLibro: "https://m.media-amazon.com/images/I/71aFt4+OTOL.jpg",
      nombreLibreria: "Biblioteca Central",
      ubicacionLibreria: "Av. Principal #123",
      fechaReserva: DateTime.now().subtract(const Duration(days: 1)),
      estado: "Listo para recoger",
    ),
    ReservaVista(
      idReserva: "res002",
      tituloLibro: "1984",
      autorLibro: "George Orwell",
      imagenLibro: "https://m.media-amazon.com/images/I/71kxa1-0mfL.jpg",
      nombreLibreria: "Biblioteca Este",
      ubicacionLibreria: "Calle Oriente #45",
      fechaReserva: DateTime.now().subtract(const Duration(days: 3)),
      estado: "Por expirar",
    ),
  ];

  // Función para cancelar reserva
  void _cancelarReserva(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancelar Reserva"),
        content: const Text("¿Estás seguro de que deseas cancelar esta reserva? El libro volverá a estar disponible para otros."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("No, mantener"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _misReservas.removeWhere((r) => r.idReserva == id);
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Reserva cancelada correctamente")),
              );
            },
            child: const Text("Sí, cancelar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // Navegar a explorar es complejo desde aquí sin un controlador de tabs global,
                // así que simplemente mostramos un mensaje o podrías usar un callback.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ve al Catálogo para reservar libros")),
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
                      width: 80, height: 120, color: Colors.grey[300],
                      child: const Icon(Icons.book),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y Menú de opciones (3 puntos)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              reserva.tituloLibro,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _cancelarReserva(reserva.idReserva),
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                            ),
                          )
                        ],
                      ),
                      Text(
                        reserva.autorLibro,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 10),

                      // Información de la librería
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
                                const Icon(Icons.store, size: 14, color: Colors.blue),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    reserva.nombreLibreria,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reserva.ubicacionLibreria,
                              style: TextStyle(fontSize: 11, color: Colors.blue[800]),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Fecha y Estado
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Reservado: ${reserva.fechaReserva.day}/${reserva.fechaReserva.month}",
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: reserva.estado == "Por expirar" ? Colors.orange[100] : Colors.green[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              reserva.estado,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: reserva.estado == "Por expirar" ? Colors.orange[800] : Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      )
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
