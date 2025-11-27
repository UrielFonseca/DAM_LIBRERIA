class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  factory Usuario.fromMap(String id, Map<String, dynamic> data) {
    return Usuario(
      id: id,
      nombre: data['nombre'],
      correo: data['correo'],
      rol: data['rol'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
    };
  }
}
