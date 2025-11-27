import 'package:cloud_firestore/cloud_firestore.dart';


class Reserva {
  final String id;
  final String idUsuario;
  final String idLibro;
  final String idLibreria;
  final DateTime fecha;

  Reserva({
    required this.id,
    required this.idUsuario,
    required this.idLibro,
    required this.idLibreria,
    required this.fecha,
  });

  factory Reserva.fromMap(String id, Map<String, dynamic> data) {
    return Reserva(
      id: id,
      idUsuario: data['idUsuario'],
      idLibro: data['idLibro'],
      idLibreria: data['idLibreria'],
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idUsuario': idUsuario,
      'idLibro': idLibro,
      'idLibreria': idLibreria,
      'fecha': fecha,
    };
  }
}
