import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo auxiliar para la vista
class LibroVista {
  final String id;
  final String titulo;
  final String autor;
  final String imagen;
  final String genero;
  final String nombreLibreria;
  final int stock;
  final String descripcion;
  final bool esPopular;

  LibroVista({
    required this.id,
    required this.titulo,
    required this.autor,
    required this.imagen,
    required this.genero,
    required this.nombreLibreria,
    required this.stock,
    required this.descripcion,
    this.esPopular = false,
  });
}

class TabLibros extends StatefulWidget {
  const TabLibros({super.key});

  @override
  State<TabLibros> createState() => _TabLibrosState();
}

class _TabLibrosState extends State<TabLibros> {
  final TextEditingController _searchController = TextEditingController();
  String _generoSeleccionado = "Todos";

  final List<String> _generos = [
    "Todos",
    "Fantasía",
    "Ciencia Ficción",
    "Terror",
    "Romance",
    "Educativo",
    "Aventura",
    "Historia"
  ];

  List<LibroVista> _todosLosLibros = [];
  List<LibroVista> _librosFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarLibrosFirestore();
    _searchController.addListener(_filtrarLibros);
  }

  // 🔥 Cargar libros desde Firestore
  Future<void> _cargarLibrosFirestore() async {
    setState(() => _isLoading = true);

    final snapshot =
    await FirebaseFirestore.instance.collection("libros").get();

    List<LibroVista> temp = snapshot.docs.map((doc) {
      final data = doc.data();

      bool esPop = (data["existencias"] as int) < 5;

      return LibroVista(
        id: doc.id,
        titulo: data["nombre"] ?? "Sin nombre",
        autor: data["autor"] ?? "Desconocido",
        imagen: data["imagen"] ?? "",
        genero: data["genero"] ?? "N/A",
        nombreLibreria: data["idLibreria"] ?? "Librería",
        stock: data["existencias"] ?? 0,
        descripcion: data["descripcion"] ?? "",
        esPopular: esPop,
      );
    }).toList();

    setState(() {
      _todosLosLibros = temp;
      _librosFiltrados = temp;
      _isLoading = false;
    });
  }

  void _filtrarLibros() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      _librosFiltrados = _todosLosLibros.where((libro) {
        final coincideNombre =
        libro.titulo.toLowerCase().contains(query);

        final coincideGenero = _generoSeleccionado == "Todos" ||
            libro.genero == _generoSeleccionado;

        return coincideNombre && coincideGenero;
      }).toList();
    });
  }

  // ⬇ FUNCIONALIDAD DE RESERVA
  Future<void> _reservarLibro(String libroId, String userEmail) async {
    final ref = FirebaseFirestore.instance.collection("libros").doc(libroId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data() as Map<String, dynamic>;

      List reservas = data["reservas"] ?? [];

      bool yaReservado = reservas.any((r) => r["email"] == userEmail);
      if (yaReservado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ya reservaste este libro")),
        );
        return;
      }

      reservas.add({
        "email": userEmail,
        "fecha": DateTime.now().toIso8601String(),
      });

      transaction.update(ref, {"reservas": reservas});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Libro reservado correctamente")),
    );

    Navigator.pop(context);
  }

  // ⬇ DETALLES
  void _mostrarDetalleLibro(BuildContext context, LibroVista libro) {
    final userEmail = FirebaseAuth.instance.currentUser!.email;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection("libros").doc(libro.id).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final reservas = List<Map<String, dynamic>>.from(data["reservas"] ?? []);

            bool yaReservado = reservas.any((r) => r["email"] == userEmail);
            int posicion = yaReservado ? reservas.indexWhere((r) => r["email"] == userEmail) + 1 : -1;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: ListView(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                libro.imagen,
                                height: 180,
                                width: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 180,
                                  width: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.book),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(libro.titulo,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                  Text(libro.autor,
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.grey[700])),
                                  const SizedBox(height: 10),
                                  Chip(
                                    label: Text(libro.genero),
                                    backgroundColor: Colors.blue[50],
                                  ),
                                  const SizedBox(height: 10),
                                  Text("Biblioteca:",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  Text(libro.nombreLibreria,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ],
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Text("Sinopsis",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(libro.descripcion,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black87)),
                        const SizedBox(height: 40),

                        // ⬇ ⬇ ⬇ BOTÓN ARREGLADO (AQUÍ ESTABA TU FALLO)
                        if (!yaReservado)
                          ElevatedButton(
                            onPressed: () =>
                                _reservarLibro(libro.id, userEmail!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(15),
                            ),
                            child: Text(
                              libro.stock > 0
                                  ? "Reservar libro"
                                  : "Unirse a la lista de espera",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ),

                        if (yaReservado)
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              "Ya estás en la lista de espera.\nTu posición: $posicion",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),

                        if (libro.stock > 0)
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12)),
                            child: const Text(
                              "Disponible — hay ejemplares en existencia.",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final populares = _todosLosLibros.where((l) => l.esPopular).toList();
    final mostrarPopulares =
        _generoSeleccionado == "Todos" && _searchController.text.isEmpty;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar...",
                      filled: true,
                      fillColor: Colors.grey[200],
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      _generoSeleccionado = value;
                      _filtrarLibros();
                    });
                  },
                  icon: const Icon(Icons.tune),
                  itemBuilder: (_) => _generos
                      .map((g) => PopupMenuItem(
                    value: g,
                    child: Text(g),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),

        // CARRUSEL POPULARES
        if (mostrarPopulares && populares.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: populares.length,
                itemBuilder: (_, index) {
                  final libro = populares[index];
                  return GestureDetector(
                    onTap: () => _mostrarDetalleLibro(context, libro),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 15),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                libro.imagen,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey[300]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(libro.titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(libro.nombreLibreria,
                              maxLines: 1,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // GRID
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final libro = _librosFiltrados[index];
                return GestureDetector(
                  onTap: () => _mostrarDetalleLibro(context, libro),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(2, 4))
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              libro.imagen,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey[300]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(libro.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        Text(libro.autor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                            TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
              childCount: _librosFiltrados.length,
            ),
          ),
        ),
      ],
    );
  }
}
