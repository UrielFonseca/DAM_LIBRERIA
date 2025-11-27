import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// Importamos solo los modelos necesarios
import '../models/ModeloLibro.dart';
import '../models/ModeloReserva.dart';

class UsuariosBD {

  static Future<Database> _abrirDB() async {
    return openDatabase(
      join(await getDatabasesPath(), "usuarios_biblioteca.db"),
      version: 1,
      onCreate: (db, version) async {
        // 1. TABLA LIBROS
        // Agregamos 'idLibreria' para diferenciar el stock de cada biblioteca
        await db.execute('''
          CREATE TABLE LIBROS(
            id TEXT PRIMARY KEY, 
            nombre TEXT, 
            descripcion TEXT, 
            autor TEXT, 
            imagen TEXT, 
            genero TEXT, 
            existencias INTEGER,
            idLibreria TEXT 
          )
        ''');

        // 2. TABLA RESERVAS
        await db.execute('''
          CREATE TABLE RESERVAS(
            id TEXT PRIMARY KEY,
            idUsuario TEXT,
            idLibro TEXT,
            idLibreria TEXT,
            fecha TEXT
          )
        ''');

        // 3. TABLA LISTA_ESPERA (PILA LIFO)
        // Sin modelo, datos crudos para manejar la cola
        await db.execute('''
          CREATE TABLE LISTA_ESPERA(
            id TEXT PRIMARY KEY,
            idUsuario TEXT,
            idLibro TEXT,
            idLibreria TEXT,
            fechaSolicitud TEXT,
            estado TEXT
          )
        ''');
      },
    );
  }

  // ==========================================
  //                 CRUD LIBROS
  // ==========================================

  // Insertar libro (Útil para cargar datos iniciales)
  static Future<int> insertarLibro(Libro libro, String idLibreria) async {
    Database db = await _abrirDB();
    Map<String, dynamic> datos = libro.toMap();
    datos['idLibreria'] = idLibreria;
    // Aseguramos que el ID del modelo se guarde
    datos['id'] = libro.id;

    return db.insert("LIBROS", datos, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Obtener libros (Soporta filtro por nombre para la barra de búsqueda)
  static Future<List<Map<String, dynamic>>> obtenerLibros({String query = ''}) async {
    Database db = await _abrirDB();
    if (query.isNotEmpty) {
      return db.query("LIBROS", where: "nombre LIKE ?", whereArgs: ['%$query%']);
    } else {
      return db.query("LIBROS");
    }
  }

  // Actualizar Stock (Restar al reservar)
  static Future<int> actualizarStock(String idLibro, int nuevoStock) async {
    Database db = await _abrirDB();
    return db.update("LIBROS",
        {'existencias': nuevoStock},
        where: "id = ?",
        whereArgs: [idLibro]
    );
  }

  // ==========================================
  //                 CRUD RESERVAS
  // ==========================================

  static Future<int> insertarReserva(Reserva r) async {
    Database db = await _abrirDB();
    Map<String, dynamic> datos = r.toMap();
    // SQLite guarda fechas como texto ISO8601
    datos['fecha'] = r.fecha.toIso8601String();
    return db.insert("RESERVAS", datos, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Reserva>> mostrarReservas(String idUsuario) async {
    Database db = await _abrirDB();
    List<Map<String, dynamic>> temp = await db.query(
        "RESERVAS",
        where: "idUsuario = ?",
        whereArgs: [idUsuario]
    );

    return List.generate(temp.length, (index) {
      return Reserva(
        id: temp[index]['id'],
        idUsuario: temp[index]['idUsuario'],
        idLibro: temp[index]['idLibro'],
        idLibreria: temp[index]['idLibreria'],
        fecha: DateTime.parse(temp[index]['fecha']),
      );
    });
  }

  static Future<int> eliminarReserva(String idReserva) async {
    Database db = await _abrirDB();
    return db.delete("RESERVAS", where: "id = ?", whereArgs: [idReserva]);
  }

  // ==========================================
  //       MANEJO DE PILA (LISTA DE ESPERA)
  // ==========================================

  // 1. PUSH: Agregar a la pila
  static Future<int> pushPila({
    required String idUsuario,
    required String idLibro,
    required String idLibreria
  }) async {
    Database db = await _abrirDB();

    Map<String, dynamic> itemPila = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(), // ID único simple
      'idUsuario': idUsuario,
      'idLibro': idLibro,
      'idLibreria': idLibreria,
      'fechaSolicitud': DateTime.now().toIso8601String(),
      'estado': 'pendiente'
    };

    return db.insert("LISTA_ESPERA", itemPila, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 2. PEEK/LIST: Ver mi pila (Orden LIFO por fecha descendente)
  static Future<List<Map<String, dynamic>>> obtenerPila(String idUsuario) async {
    Database db = await _abrirDB();

    // Hacemos un JOIN para traer el nombre del libro y la imagen automáticamente
    return db.rawQuery('''
      SELECT 
        le.id as idSolicitud,
        le.fechaSolicitud,
        le.estado,
        le.idLibreria,
        l.nombre as tituloLibro,
        l.autor as autorLibro,
        l.imagen as imagenLibro
      FROM LISTA_ESPERA le
      INNER JOIN LIBROS l ON le.idLibro = l.id
      WHERE le.idUsuario = ?
      ORDER BY le.fechaSolicitud DESC
    ''', [idUsuario]);
  }

  // 3. POP/REMOVE: Salir de la pila
  static Future<int> eliminarDePila(String idSolicitud) async {
    Database db = await _abrirDB();
    return db.delete("LISTA_ESPERA", where: "id = ?", whereArgs: [idSolicitud]);
  }
}
