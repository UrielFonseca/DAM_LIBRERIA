import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para obtener el ID del usuario actual
import '../database/UsuariosBD.dart'; // Importamos tu base de datos
import '../models/ModeloLibro.dart';  // Importamos el modelo base
import '../models/ModeloReserva.dart'; // Para crear objetos de reserva

// Modelo auxiliar para la vista (Mantenemos este para facilitar la UI)
class LibroVista {
  final String id; // Necesitamos el ID para la BD
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
  final List<String> _generos = ["Todos", "Fantasía", "Ciencia Ficción", "Terror", "Romance", "Educativo", "Aventura", "Historia"];

  // Lista dinámica que vendrá de la BD
  List<LibroVista> _todosLosLibros = [];
  List<LibroVista> _librosFiltrados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchController.addListener(_filtrarLibros);
  }

  // Carga datos desde SQLite y siembra datos si está vacía
  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    // 1. Obtener libros de la BD
    var librosMap = await UsuariosBD.obtenerLibros();

    // 2. Si la BD está vacía, insertamos datos de prueba (Seed)
    if (librosMap.isEmpty) {
      await _insertarDatosPrueba();
      librosMap = await UsuariosBD.obtenerLibros(); // Recargar
    }

    // 3. Convertir Mapas de BD a objetos LibroVista
    List<LibroVista> tempLibros = librosMap.map((map) {
      // Determinamos si es popular arbitrariamente o por lógica (ej. stock bajo = popular)
      bool esPop = (map['existencias'] as int) < 5;

      return LibroVista(
        id: map['id'],
        titulo: map['nombre'],
        autor: map['autor'],
        imagen: map['imagen'],
        genero: map['genero'],
        nombreLibreria: map['idLibreria'], // Aquí usaremos el ID como nombre por ahora
        stock: map['existencias'],
        descripcion: map['descripcion'],
        esPopular: esPop,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _todosLosLibros = tempLibros;
        _librosFiltrados = tempLibros;
        _isLoading = false;
        _filtrarLibros(); // Aplicar filtros iniciales si los hay
      });
    }
  }

  Future<void> _insertarDatosPrueba() async {
    // Lista de libros iniciales
    List<Map<String, dynamic>> datos = [
      {
        'libro': Libro(id: 'l1', nombre: 'El Principito', descripcion: 'Historia sobre un pequeño príncipe...', autor: 'Antoine de Saint-Exupéry', imagen: 'https://m.media-amazon.com/images/I/71aFt4+OTOL.jpg', genero: 'Fantasía', existencias: 3),
        'libreria': 'Biblioteca Central'
      },
      {
        'libro': Libro(id: 'l2', nombre: 'El Principito', descripcion: 'Historia sobre un pequeño príncipe...', autor: 'Antoine de Saint-Exupéry', imagen: 'https://m.media-amazon.com/images/I/71aFt4+OTOL.jpg', genero: 'Fantasía', existencias: 10),
        'libreria': 'Biblioteca Sur'
      },
      {
        'libro': Libro(id: 'l3', nombre: 'Cien Años de Soledad', descripcion: 'La historia de la familia Buendía...', autor: 'Gabriel García Márquez', imagen: 'https://images.penguinrandomhouse.com/cover/9780307474728', genero: 'Fantasía', existencias: 0),
        'libreria': 'Biblioteca Norte'
      },
      {
        'libro': Libro(id: 'l4', nombre: 'It', descripcion: 'Un payaso aterroriza a los niños...', autor: 'Stephen King', imagen: 'https://m.media-amazon.com/images/I/71qZ+K+pXSL._AC_UF1000,1000_QL80_.jpg', genero: 'Terror', existencias: 5),
        'libreria': 'Biblioteca Central'
      },
    ];

    for (var d in datos) {
      await UsuariosBD.insertarLibro(d['libro'] as Libro, d['libreria'] as String);
    }
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

  // Lógica para PROCESAR LA RESERVA o LISTA DE ESPERA
  Future<void> _procesarAccion(LibroVista libro) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Usuario no identificado")));
      return;
    }

    // 1. Si hay Stock -> RESERVAR
    if (libro.stock > 0) {
      // Crear objeto reserva
      final nuevaReserva = Reserva(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        idUsuario: user.uid,
        idLibro: libro.id,
        idLibreria: libro.nombreLibreria,
        fecha: DateTime.now(),
      );

      // Guardar reserva
      await UsuariosBD.insertarReserva(nuevaReserva);

      // Actualizar Stock (Resta 1)
      await UsuariosBD.actualizarStock(libro.id, libro.stock - 1);

      if (mounted) {
        Navigator.pop(context); // Cerrar modal
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("¡Libro reservado! Recógelo en: ${libro.nombreLibreria}")));
        _cargarDatos(); // Recargar vista para ver nuevo stock
      }
    }
    // 2. Si NO hay Stock -> LISTA DE ESPERA
    else {
      await UsuariosBD.pushPila(
          idUsuario: user.uid,
          idLibro: libro.id,
          idLibreria: libro.nombreLibreria
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Te has unido a la fila de espera exitosamente.")));
        // No hace falta recargar stock, pero sí confirmación visual
      }
    }
  }

  void _mostrarDetalleLibro(BuildContext context, LibroVista libro) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  ],
                ),
              ),

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
                      onPressed: () => _procesarAccion(libro),
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
    // Si está cargando, mostramos spinner
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final populares = _todosLosLibros.where((l) => l.esPopular).toList();
    final mostrarPopulares = _generoSeleccionado == "Todos" && _searchController.text.isEmpty;

    return CustomScrollView(
      slivers: [
        // 1. BUSCADOR Y FILTROS
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.tune, color: Colors.blue),
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
                              Icon(choice == _generoSeleccionado ? Icons.check_circle : Icons.circle_outlined, color: choice == _generoSeleccionado ? Colors.blue : Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              Text(choice, style: TextStyle(fontWeight: choice == _generoSeleccionado ? FontWeight.bold : FontWeight.normal)),
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

        // 2. CARRUSEL DE POPULARES
        if (mostrarPopulares && populares.isNotEmpty) ...[
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
              height: 200,
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
                                child: Image.network(libro.imagen, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c,o,s) => Container(color: Colors.grey[300])),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(libro.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(libro.nombreLibreria, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // 3. RESULTADOS GRID
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 25, 16, 10),
            child: Text(
              mostrarPopulares ? "Explorar Catálogo" : "Resultados (${_librosFiltrados.length})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          sliver: _librosFiltrados.isEmpty
              ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.only(top: 50), child: Text("No hay libros disponibles"))))
              : SliverGrid(
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
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: Image.network(libro.imagen, fit: BoxFit.cover, errorBuilder: (c,o,s) => Container(color: Colors.grey[200])),
                              ),
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
                                    Text(libro.titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.1)),
                                    const SizedBox(height: 4),
                                    Text(libro.genero, style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.store, size: 12, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(libro.nombreLibreria, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }
}
