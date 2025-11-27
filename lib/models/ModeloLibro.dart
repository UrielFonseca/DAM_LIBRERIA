class Libro {
  final String id;
  final String nombre;
  final String descripcion;
  final String autor;
  final String imagen;
  final String genero;
  final int existencias;

  Libro({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.autor,
    required this.imagen,
    required this.genero,
    required this.existencias,
  });

  factory Libro.fromMap(String id, Map<String, dynamic> data) {
    return Libro(
      id: id,
      nombre: data['nombre'],
      descripcion: data['descripcion'],
      autor: data['autor'],
      imagen: data['imagen'],
      genero: data['genero'],
      existencias: data['existencias'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'autor': autor,
      'imagen': imagen,
      'genero': genero,
      'existencias': existencias,
    };
  }
}
