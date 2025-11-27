import 'package:flutter/material.dart';

// Modelo auxiliar para la vista
class LibroVista {
  final String titulo;
  final String autor;
  final String imagen;
  final String genero;
  final String nombreLibreria;
  final int stock;
  final String descripcion;
  final bool esPopular;

  LibroVista({
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
  final List<String> _generos = ["Todos", "Fantasía", "Ciencia Ficción", "Terror", "Romance", "Educativo", "Aventura", "Historia"];

  // DATOS DE PRUEBA
  final List<LibroVista> _todosLosLibros = [
    LibroVista(
      titulo: "El Principito",
      autor: "Antoine de Saint-Exupéry",
      imagen: "https://m.media-amazon.com/images/I/71aFt4+OTOL.jpg",
      genero: "Fantasía",
      nombreLibreria: "Biblioteca Central",
      stock: 3,
      descripcion: "Historia sobre un pequeño príncipe...",
      esPopular: true,
    ),
    LibroVista(
      titulo: "El Principito",
      autor: "Antoine de Saint-Exupéry",
      imagen: "https://m.media-amazon.com/images/I/71aFt4+OTOL.jpg",
      genero: "Fantasía",
      nombreLibreria: "Biblioteca Sur",
      stock: 10,
      descripcion: "Historia sobre un pequeño príncipe (Edición Sur)...",
      esPopular: false,
    ),
    LibroVista(
      titulo: "Cien Años de Soledad",
      autor: "Gabriel García Márquez",
      imagen: "https://images.penguinrandomhouse.com/cover/9780307474728",
      genero: "Fantasía",
      nombreLibreria: "Biblioteca Norte",
      stock: 0,
      descripcion: "La historia de la familia Buendía...",
      esPopular: true,
    ),
    LibroVista(
      titulo: "It",
      autor: "Stephen King",
      imagen: "https://m.media-amazon.com/images/I/71qZ+K+pXSL._AC_UF1000,1000_QL80_.jpg",
      genero: "Terror",
      nombreLibreria: "Biblioteca Central",
      stock: 5,
      descripcion: "Un payaso aterroriza a los niños...",
      esPopular: true,
    ),
    LibroVista(
      titulo: "1984",
      autor: "George Orwell",
      imagen: "https://m.media-amazon.com/images/I/71kxa1-0mfL.jpg",
      genero: "Ciencia Ficción",
      nombreLibreria: "Biblioteca Este",
      stock: 2,
      descripcion: "Una distopía totalitaria...",
      esPopular: true,
    ),
    LibroVista(
      titulo: "Dune",
      autor: "Frank Herbert",
      imagen: "https://m.media-amazon.com/images/I/41jM5F6rGRL._AC_SY445_SX342_.jpg",
      genero: "Ciencia Ficción",
      nombreLibreria: "Biblioteca Central",
      stock: 8,
      descripcion: "La lucha por el planeta Arrakis...",
      esPopular: false,
    ),
  ];

  List<LibroVista> _librosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _librosFiltrados = _todosLosLibros;
    _searchController.addListener(_filtrarLibros);
  }

  void _filtrarLibros() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _librosFiltrados = _todosLosLibros.where((libro) {
        final coincideNombre = libro.titulo.toLowerCase().contains(query);
        final coincideGenero = _generoSeleccionado == "Todos" || libro.genero == _generoSeleccionado;
        return coincideNombre && coincideGenero;
      }).toList();
    });
  }

  void _mostrarDetalleLibro(BuildContext context, LibroVista libro) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Para bordes redondeados limpios
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
          height: MediaQuery.of(context).size.height * 0.85, // Ocupa 85% pantalla
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior del modal (Drag handle)
              Center(
                child: Container(
                  height: 5, width: 50,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  children: [
                    // Imagen y Título
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(libro.imagen, height: 180, width: 120, fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => Container(height: 180, width: 120, color: Colors.grey, child: const Icon(Icons.book))),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(libro.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              Text(libro.autor, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                              const SizedBox(height: 10),
                              Chip(label: Text(libro.genero), backgroundColor: Colors.blue[50]),
                              const SizedBox(height: 10),
                              const Text("Biblioteca:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(libro.nombreLibreria, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text("Sinopsis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(libro.descripcion, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // Botón de acción fijo abajo
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: libro.stock > 0 ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: libro.stock > 0 ? Colors.green : Colors.orange),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(libro.stock > 0 ? "Disponible" : "Agotado",
                            style: TextStyle(fontWeight: FontWeight.bold, color: libro.stock > 0 ? Colors.green : Colors.orange)),
                        Text("${libro.stock} unidades", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(libro.stock > 0 ? "Reservando..." : "Uniéndose a fila...")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: libro.stock > 0 ? Colors.green : Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        libro.stock > 0 ? "Reservar" : "Hacer Fila",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final populares = _todosLosLibros.where((l) => l.esPopular).toList();
    final mostrarPopulares = _generoSeleccionado == "Todos" && _searchController.text.isEmpty;

    return CustomScrollView(
      slivers: [
        // 1. BUSCADOR Y FILTRO (No fijos, scrollean con la pagina)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar por título...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.tune, color: Colors.blue), // Icono de filtros
                    onSelected: (String genero) {
                      setState(() {
                        _generoSeleccionado = genero;
                        _filtrarLibros();
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return _generos.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Row(
                            children: [
                              Icon(
                                choice == _generoSeleccionado ? Icons.check_circle : Icons.circle_outlined,
                                color: choice == _generoSeleccionado ? Colors.blue : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(choice, style: TextStyle(
                                  fontWeight: choice == _generoSeleccionado ? FontWeight.bold : FontWeight.normal
                              )),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. TÍTULO Y CARRUSEL POPULARES (Solo visible si no hay filtros activos)
        if (mostrarPopulares) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                children: const [
                  Icon(Icons.local_fire_department, color: Colors.orange),
                  SizedBox(width: 5),
                  Text("Tendencias", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200, // Altura del carrusel
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: populares.length,
                itemBuilder: (context, index) {
                  final libro = populares[index];
                  return GestureDetector(
                    onTap: () => _mostrarDetalleLibro(context, libro),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2,4))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(libro.imagen, fit: BoxFit.cover, width: double.infinity,
                                    errorBuilder: (c,o,s) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image))),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(libro.titulo, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(libro.nombreLibreria, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // 3. TÍTULO GRID EXPLORAR
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 25, 16, 10),
            child: Text(
              mostrarPopulares ? "Explorar Catálogo" : "Resultados de búsqueda (${_librosFiltrados.length})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // 4. GRID DE RESULTADOS (Scroll infinito o lista completa)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          sliver: _librosFiltrados.isEmpty
              ? SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: const [
                  SizedBox(height: 50),
                  Icon(Icons.search_off, size: 50, color: Colors.grey),
                  Text("No se encontraron libros"),
                ],
              ),
            ),
          )
              : SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65, // Ajusta la altura de las tarjetas
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
                        BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // IMAGEN
                        Expanded(
                          flex: 4,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: Image.network(libro.imagen, fit: BoxFit.cover,
                                    errorBuilder: (c,o,s) => Container(color: Colors.grey[200])),
                              ),
                              // Badge de Agotado
                              if (libro.stock == 0)
                                Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                                    child: const Text("AGOTADO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // INFO
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(libro.titulo, maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.1)),
                                    const SizedBox(height: 4),
                                    Text(libro.genero, style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.store, size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(libro.nombreLibreria, maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _librosFiltrados.length,
            ),
          ),
        ),

        // Espacio extra al final para que no se corte con bordes de pantalla
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }
}
