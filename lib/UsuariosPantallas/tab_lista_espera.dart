import 'package:flutter/material.dart';

// Modelo auxiliar para la vista de Lista de Espera (Simula Solicitud + Libro + Librería)
class ListaEsperaVista {
  final String idSolicitud;
  final String tituloLibro;
  final String autorLibro;
  final String imagenLibro;
  final String nombreLibreria;
  final int posicionEnPila; // Tu posición actual en la pila
  final DateTime fechaSolicitud;

  ListaEsperaVista({
    required this.idSolicitud,
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
  // DATOS DE PRUEBA (Dummies)
  final List<ListaEsperaVista> _miListaEspera = [
    ListaEsperaVista(
      idSolicitud: "sol001",
      tituloLibro: "Cien Años de Soledad",
      autorLibro: "Gabriel García Márquez",
      imagenLibro: "https://images.penguinrandomhouse.com/cover/9780307474728",
      nombreLibreria: "Biblioteca Norte",
      posicionEnPila: 1, // Estás en el tope de la pila (el siguiente)
      fechaSolicitud: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ListaEsperaVista(
      idSolicitud: "sol002",
      tituloLibro: "Dune",
      autorLibro: "Frank Herbert",
      imagenLibro: "https://m.media-amazon.com/images/I/41jM5F6rGRL._AC_SY445_SX342_.jpg",
      nombreLibreria: "Biblioteca Central",
      posicionEnPila: 5, // Hay 4 personas (o elementos) encima de ti
      fechaSolicitud: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // Función para salir de la lista de espera
  void _salirDeLaPila(String id) {
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
            onPressed: () {
              setState(() {
                _miListaEspera.removeWhere((item) => item.idSolicitud == id);
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Has salido de la lista de espera")),
              );
            },
            child: const Text("Sí, salir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              onPressed: () => _salirDeLaPila(solicitud.idSolicitud),
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
