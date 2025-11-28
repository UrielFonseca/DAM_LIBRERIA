import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// CLASE PRINCIPAL: PANTALLA ADMIN
// ==========================================
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
    Navigator.pop(context); // Cierra el Drawer
  }

  // LISTA DE VISTAS (Aquí conectamos todas las clases definidas abajo)
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

// =======================================================
// 2. VISTA DASHBOARD (Resumen)
// =======================================================
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

// =======================================================
// 3. VISTA LIBROS (CRUD)
// =======================================================
class VistaLibros extends StatelessWidget {
  const VistaLibros({super.key});

  void _mostrarDialogo(BuildContext context, {DocumentSnapshot? libro}) {
    final nombreCtrl = TextEditingController(text: libro?['nombre'] ?? '');
    final autorCtrl = TextEditingController(text: libro?['autor'] ?? '');
    final generoCtrl = TextEditingController(text: libro?['genero'] ?? '');
    final stockCtrl = TextEditingController(text: libro?['existencias']?.toString() ?? '1');
    final imgCtrl = TextEditingController(text: libro?['imagen'] ?? '');
    final descCtrl = TextEditingController(text: libro?['descripcion'] ?? '');

    // Selector de librería (opcional)
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

// =======================================================
// 4. VISTA LIBRERÍAS (CRUD)
// =======================================================
class VistaLibrerias extends StatelessWidget {
  const VistaLibrerias({super.key});

  void _dialogo(BuildContext context, {DocumentSnapshot? doc}) {
    final nombreCtrl = TextEditingController(text: doc?['nombre'] ?? '');
    final ubicacionCtrl = TextEditingController(text: doc?['ubicacion'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc == null ? "Nueva Librería" : "Editar Librería"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: ubicacionCtrl, decoration: const InputDecoration(labelText: "Ubicación")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final data = {'nombre': nombreCtrl.text, 'ubicacion': ubicacionCtrl.text, if(doc==null) 'estanterias': []};
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
              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(doc['nombre']),
                subtitle: Text(doc['ubicacion']),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _dialogo(context, doc: doc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// 5. VISTA RESERVAS (Aquí empieza lo que te faltaba)
// =======================================================
class VistaReservas extends StatelessWidget {
  const VistaReservas({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reservas').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final reservas = snapshot.data!.docs;

        if (reservas.isEmpty) {
          return const Center(child: Text("No hay reservas activas"));
        }

        return ListView.builder(
          itemCount: reservas.length,
          itemBuilder: (context, index) {
            final doc = reservas[index];
            final data = doc.data() as Map<String, dynamic>;
            final String idLibro = data['idLibro'] ?? '';

            // Cálculo de expiración (Ej: 3 días)
            DateTime fecha;
            if (data['fecha'] is Timestamp) {
              fecha = (data['fecha'] as Timestamp).toDate();
            } else {
              fecha = DateTime.now();
            }
            final vencida = DateTime.now().difference(fecha).inDays > 3;

            return Card(
              color: vencida ? Colors.red[50] : Colors.white,
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(Icons.bookmark_border, color: vencida ? Colors.red : Colors.deepPurple),
                // 1. Buscamos el nombre del libro
                title: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('libros').doc(idLibro).get(),
                  builder: (context, snapshotLibro) {
                    if (snapshotLibro.hasData && snapshotLibro.data != null) {
                      return Text(snapshotLibro.data!['nombre'] ?? 'Libro no encontrado');
                    }
                    return const Text("Cargando libro...");
                  },
                ),
                // 2. Buscamos al usuario
                subtitle: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(data['idUsuario']).get(),
                    builder: (context, snapshotUser) {
                      String nombreUser = "Usuario desconocido";
                      if(snapshotUser.hasData && snapshotUser.data!.exists) {
                        nombreUser = snapshotUser.data!['nombre'] ?? snapshotUser.data!['email'];
                      }
                      return Text("Usuario: $nombreUser\nFecha: ${fecha.day}/${fecha.month} ${vencida ? '(VENCIDA)' : ''}");
                    }
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => doc.reference.delete(), // Borrar reserva
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// =======================================================
// 6. VISTA USUARIOS (Aquí termina el archivo)
// =======================================================
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

            return ExpansionTile(
              leading: const Icon(Icons.person),
              title: Text(data['nombre'] ?? 'Usuario'),
              subtitle: Text(data['email'] ?? data['correo'] ?? ''),
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('reservas').where('idUsuario', isEqualTo: user.id).snapshots(),
                  builder: (context, snapRes) {
                    if (!snapRes.hasData || snapRes.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text("Sin reservas."));

                    return Column(
                      children: snapRes.data!.docs.map((r) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.book, size: 16),
                        title: Text("Reserva ID: ${r.id.substring(0,5)}..."),
                        trailing: IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.red), onPressed: () => r.reference.delete()),
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