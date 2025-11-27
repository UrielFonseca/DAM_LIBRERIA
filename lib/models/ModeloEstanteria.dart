class Estanteria {
  final String id;
  final String genero;
  final List<String> libros; // IDs de libros

  Estanteria({
    required this.id,
    required this.genero,
    required this.libros,
  });

  factory Estanteria.fromMap(String id, Map<String, dynamic> data) {
    return Estanteria(
      id: id,
      genero: data['genero'],
      libros: List<String>.from(data['libros']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'genero': genero,
      'libros': libros,
    };
  }
}
