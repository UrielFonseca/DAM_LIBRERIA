import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {
  int _vistaActual = 0;
  String _titulo = "Dashboard Admin";

  // Función para cambiar de vista desde el menú lateral
  void _cambiarVista(int index, String titulo) {
    setState(() {
      _vistaActual = index;
      _titulo = titulo;
    });
    Navigator.pop(context);
  }

  // LISTA DE VISTAS
  final List<Widget> _vistas = [
    const VistaDashboard(),    // Índice 0
    const VistaLibros(),       // Índice 1
    const VistaLibrerias(),    // Índice 2
    const VistaReservas(),     // Índice 3
    const VistaUsuarios(),     // Índice 4
  ];

  @override
  Widget build(BuildContext context) {
    // Obtenemos el correo actual para mostrarlo en el menú
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "admin@tigrestec.com";

    return Scaffold(
      appBar: AppBar(
        title: Text(_titulo),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              accountName: const Text("Administrador", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              accountEmail: Text(email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.deepPurple),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              selected: _vistaActual == 0,
              onTap: () => _cambiarVista(0, "Dashboard"),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text("Gestión de Libros"),
              selected: _vistaActual == 1,
              onTap: () => _cambiarVista(1, "Gestión de Libros"),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text("Gestión Librerías"),
              selected: _vistaActual == 2,
              onTap: () => _cambiarVista(2, "Gestión Librerías"),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text("Reservas"),
              selected: _vistaActual == 3,
              onTap: () => _cambiarVista(3, "Control de Reservas"),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Usuarios"),
              selected: _vistaActual == 4,
              onTap: () => _cambiarVista(4, "Lista de Usuarios"),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: _vistas[_vistaActual],
    );
  }
}

//VISTA DASHBOARD
class VistaDashboard extends StatelessWidget {
  const VistaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Resumen General", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _infoCard("Usuarios", Icons.people, Colors.blue, "users"),
              _infoCard("Libros", Icons.book, Colors.orange, "libros"),
              _infoCard("Librerías", Icons.store, Colors.purple, "librerias"),
              _infoCard("Reservas", Icons.bookmark, Colors.green, "reservas"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String titulo, IconData icono, Color color, String coleccion) {
    // Manejo especial para la colección 'reservas'
    if (coleccion == 'reservas') {
      return Card(
        elevation: 4,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('libros').snapshots(),
          builder: (context, snapshot) {
            String count = "0";
            if (snapshot.hasData) {
              int totalReservas = 0;
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final reservasArray = data['reservas'] as List<dynamic>?;
                totalReservas += reservasArray?.length ?? 0;
              }
              count = totalReservas.toString();
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 40, color: color),
                const SizedBox(height: 10),
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(count, style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
              ],
            );
          },
        ),
      );
    }

    //colecciones (users, libros, librerias)
    return Card(
      elevation: 4,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(coleccion).snapshots(),
        builder: (context, snapshot) {
          String count = "...";
          if (snapshot.hasData) count = snapshot.data!.docs.length.toString();
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 40, color: color),
              const SizedBox(height: 10),
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(count, style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
            ],
          );
        },
      ),
    );
  }
}

//VISTA LIBROS
class VistaLibros extends StatelessWidget {
  const VistaLibros({super.key});

  void _mostrarDialogo(BuildContext context, {DocumentSnapshot? libro}) {
    final nombreCtrl = TextEditingController(text: libro?['nombre'] ?? '');
    final autorCtrl = TextEditingController(text: libro?['autor'] ?? '');
    final generoCtrl = TextEditingController(text: libro?['genero'] ?? '');
    final stockCtrl = TextEditingController(text: libro?['existencias']?.toString() ?? '1');
    final imgCtrl = TextEditingController(text: libro?['imagen'] ?? '');
    final descCtrl = TextEditingController(text: libro?['descripcion'] ?? '');

    // Selector de librería
    String? idLibreriaSel = libro != null && (libro.data() as Map).containsKey('idLibreria')
        ? (libro.data() as Map)['idLibreria'] : null;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(libro == null ? "Agregar Libro" : "Editar Libro"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
                    TextField(controller: autorCtrl, decoration: const InputDecoration(labelText: "Autor")),
                    // Dropdown Librerías
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('librerias').snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox();
                        return DropdownButtonFormField<String>(
                          value: idLibreriaSel,
                          hint: const Text("Seleccionar Librería"),
                          items: snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['nombre']))).toList(),
                          onChanged: (v) => setState(() => idLibreriaSel = v),
                        );
                      },
                    ),
                    TextField(controller: generoCtrl, decoration: const InputDecoration(labelText: "Género")),
                    TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: "Existencias"), keyboardType: TextInputType.number),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Descripción")),
                    TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: "URL Imagen")),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () {
                    final data = {
                      'nombre': nombreCtrl.text,
                      'autor': autorCtrl.text,
                      'genero': generoCtrl.text,
                      'existencias': int.tryParse(stockCtrl.text) ?? 0,
                      'descripcion': descCtrl.text,
                      'imagen': imgCtrl.text,
                      'idLibreria': idLibreriaSel ?? '',
                      "reservas": [],

                    };
                    if (libro == null) {
                      FirebaseFirestore.instance.collection('libros').add(data);
                    } else {
                      FirebaseFirestore.instance.collection('libros').doc(libro.id).update(data);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Guardar"),
                )
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogo(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('libros').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final libro = snapshot.data!.docs[index];
              final data = libro.data() as Map<String, dynamic>;
              return ListTile(
                leading: data['imagen'] != null && data['imagen'].toString().isNotEmpty
                    ? Image.network(data['imagen'], width: 40, errorBuilder: (_,__,___)=>const Icon(Icons.book))
                    : const Icon(Icons.book),
                title: Text(data['nombre'] ?? 'Sin título'),
                subtitle: Text("${data['autor']} - Stock: ${data['existencias']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _mostrarDialogo(context, libro: libro)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => libro.reference.delete()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//VISTA LIBRERÍAS
class VistaLibrerias extends StatelessWidget {
  const VistaLibrerias({super.key});

  void _dialogo(BuildContext context, {DocumentSnapshot? doc}) {
    final nombreCtrl = TextEditingController(text: doc?['nombre'] ?? '');

    GeoPoint? geoPoint = doc != null && (doc.data() as Map<String, dynamic>).containsKey('Cordenadas')
        ? (doc.data() as Map<String, dynamic>)['Cordenadas'] as GeoPoint?
        : null;

    final latitudCtrl = TextEditingController(text: geoPoint?.latitude.toString() ?? '');
    final longitudCtrl = TextEditingController(text: geoPoint?.longitude.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? "Nueva Librería" : "Editar Librería"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            //CAMPOS PARA COORDENADAS
            TextField(
                controller: latitudCtrl,
                decoration: const InputDecoration(labelText: "Latitud"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true)
            ),
            TextField(
                controller: longitudCtrl,
                decoration: const InputDecoration(labelText: "Longitud"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true)
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final double? lat = double.tryParse(latitudCtrl.text);
              final double? lng = double.tryParse(longitudCtrl.text);

              //OBJETO GeoPoint y el mapa de datos
              final Map<String, dynamic> data = {
                'nombre': nombreCtrl.text,
                if (lat != null && lng != null)
                  'Cordenadas': GeoPoint(lat, lng),
                if(doc == null) 'estanterias': [],
              };
              if (doc == null) {
                FirebaseFirestore.instance.collection('librerias').add(data);
              } else {
                FirebaseFirestore.instance.collection('librerias').doc(doc.id).update(data);
              }
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _dialogo(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('librerias').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final GeoPoint? coords = data['Cordenadas'] as GeoPoint?;
              final String coordsText = (coords != null)
                  ? 'Lat: ${coords.latitude.toStringAsFixed(4)}, Lng: ${coords.longitude.toStringAsFixed(4)}'
                  : 'Coordenadas no definidas';

              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(data['nombre'] ?? 'Sin Nombre'),
                subtitle: Text(coordsText),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _dialogo(context, doc: doc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => doc.reference.delete(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//VISTA RESERVAS
  class VistaReservas extends StatefulWidget {
  const VistaReservas({super.key});

  @override
  State<VistaReservas> createState() => _VistaReservasState();
  }

  class _VistaReservasState extends State<VistaReservas> {
          String _filtro = '';
          final TextEditingController _searchController = TextEditingController();

          Widget _buildUserSubtitle(String emailUsuario, Map<String, dynamic> dataReserva, DateTime fecha, bool vencida) {
            return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').where('email', isEqualTo: emailUsuario).get(),
            builder: (context, snapshotUser) {
            String nombreUser = emailUsuario;
            String email = emailUsuario;

            if (snapshotUser.hasData && snapshotUser.data!.docs.isNotEmpty) {
              final userData = snapshotUser.data!.docs.first.data() as Map<String, dynamic>?;
                if (userData != null) {
                  nombreUser = userData['nombre'] ?? emailUsuario;
                  }
            }
            dataReserva['nombreUsuario'] = nombreUser.toLowerCase();
            dataReserva['emailUsuario'] = email.toLowerCase();
            return Text("Reservado por: $nombreUser\nFecha: ${fecha.day}/${fecha.month}/${fecha.year} ${vencida ? '(VENCIDA)' : ''}");
                }
            );
          }

          @override
          void initState() {
            super.initState();
            _searchController.addListener(() {
              setState(() {
                _filtro = _searchController.text;
              });
            });
          }

          @override
          void dispose() {
            _searchController.dispose();
            super.dispose();
          }

          @override
          Widget build(BuildContext context) {
            return Column(
            children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar Reserva (Libro o Correo)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('libros').snapshots(),
              builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No hay libros disponibles."));
                  }

                List<Map<String, dynamic>> todasReservas = [];

                for (var libroDoc in snapshot.data!.docs) {
                  final libroData = libroDoc.data() as Map<String, dynamic>;
                  final reservasArray = libroData['reservas'] as List<dynamic>?;
                  final nombreLibro = libroData['nombre'] ?? 'Libro sin nombre';
                  final idLibro = libroDoc.id;

                  if (reservasArray != null) {
                    for (var reserva in reservasArray) {
                      final Map<String, dynamic> reservaData = Map<String, dynamic>.from(reserva);
                      reservaData['idLibro'] = idLibro;
                      reservaData['nombreLibro'] = nombreLibro;
                      reservaData['emailUsuario'] = reservaData['email'] ?? '';
                      todasReservas.add(reservaData);
                    }
                  }
                }

                if (todasReservas.isEmpty) {
                  return const Center(child: Text("No hay reservas activas."));
                }

                //Aplicar Filtro
                final filtroLower = _filtro.toLowerCase();
                final reservasFiltradas = todasReservas.where((data) {
                  if (filtroLower.isEmpty) return true;
                  final bookMatch = data['nombreLibro']?.toLowerCase().contains(filtroLower) ?? false;
                  final emailMatch = data['emailUsuario']?.toLowerCase().contains(filtroLower) ?? false;
                  final nameMatch = data['nombreUsuario']?.toLowerCase().contains(filtroLower) ?? false;
                  return bookMatch || emailMatch || nameMatch;
                }).toList();
                if (reservasFiltradas.isEmpty && _filtro.isNotEmpty) {
                  return Center(child: Text("No se encontraron reservas para '$_filtro'"));
                }

                return ListView.builder(
                  itemCount: reservasFiltradas.length,
                  itemBuilder: (context, index) {
                    final data = reservasFiltradas[index];

                    DateTime fecha;
                    if (data['fecha'] is String) {
                      try {
                        fecha = DateTime.parse(data['fecha']);
                      } catch (_) {
                        fecha = DateTime.now();
                      }
                    } else if (data['fecha'] is Timestamp) {
                        fecha = (data['fecha'] as Timestamp).toDate();
                      } else {
                        fecha = DateTime.now();
                      }

                    final vencida = DateTime.now().difference(fecha).inDays > 3;

                    return Card(
                      color: vencida ? Colors.red[50] : Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Icon(Icons.bookmark_border, color: vencida ? Colors.red : Colors.deepPurple),
                        title: Text(data['nombreLibro'] ?? 'Libro Desconocido', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: _buildUserSubtitle(data['emailUsuario'], data, fecha, vencida),

                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Acción: Eliminar reserva del array del libro.")),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }
  }

//VISTA USUARIOS
class VistaUsuarios extends StatelessWidget {
  const VistaUsuarios({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final user = snapshot.data!.docs[index];
            final data = user.data() as Map<String, dynamic>;
            final userEmail = data['email'] ?? data['correo'];

            return ExpansionTile(
              leading: const Icon(Icons.person),
              title: Text(data['nombre'] ?? 'Usuario'),
              subtitle: Text(userEmail ?? 'Email no disponible'),
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('libros').snapshots(),
                  builder: (context, snapLibros) {
                    if (!snapLibros.hasData) return const Padding(padding: EdgeInsets.all(8.0), child: Text("Cargando reservas..."));

                    List<Map<String, dynamic>> reservasDelUsuario = [];

                    for (var libroDoc in snapLibros.data!.docs) {
                      final libroData = libroDoc.data() as Map<String, dynamic>;
                      final reservasArray = libroData['reservas'] as List<dynamic>?;
                      final nombreLibro = libroData['nombre'] ?? 'Libro (ID: ${libroDoc.id})';

                      if (reservasArray != null) {
                        for (var reserva in reservasArray) {
                            final Map<String, dynamic> reservaData = Map<String, dynamic>.from(reserva);
                          if (reservaData['email'] == userEmail) {
                            reservaData['nombreLibro'] = nombreLibro;
                            reservasDelUsuario.add(reservaData);
                          }
                        }
                      }
                    }
                    if (reservasDelUsuario.isEmpty) {
                      return const Padding(padding: EdgeInsets.all(8.0), child: Text("Sin reservas."));
                    }

                    //Mostrar la lista de reservas encontradas
                    return Column(
                      children: reservasDelUsuario.map((r) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.book, size: 16),
                        title: Text("Reservó: ${r['nombreLibro']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.red),
                          onPressed: null,
                        ),
                      )).toList(),
                    );
                  },
                )
              ],
            );
          },
        );
      },
    );
  }
}