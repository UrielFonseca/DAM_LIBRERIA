class Libreria {
  final String id;
  final String nombre;
  final String ubicacion;
  final List<String> estanterias; // IDs de estanterías

  Libreria({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.estanterias,
  });

  factory Libreria.fromMap(String id, Map<String, dynamic> data) {
    return Libreria(
      id: id,
      nombre: data['nombre'],
      ubicacion: data['ubicacion'],
      estanterias: List<String>.from(data['estanterias']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'ubicacion': ubicacion,
      'estanterias': estanterias,
    };
  }
}
