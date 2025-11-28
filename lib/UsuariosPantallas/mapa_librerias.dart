/*import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MapaLibrerias extends StatefulWidget {
  const MapaLibrerias({super.key});

  @override
  State<MapaLibrerias> createState() => _MapaLibreriasState();
}

class _MapaLibreriasState extends State<MapaLibrerias> {
  GoogleMapController? mapaController;
  Location location = Location();
  LatLng? ubicacionActual;

  Map<MarkerId, Marker> marcadores = {};
  LatLng? libreriaSeleccionada;

  final FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    configurarNotificaciones();
    obtenerUbicacionActual();
    cargarLibreriasFirestore();
  }

  Future<void> configurarNotificaciones() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await notifications.initialize(settings);
  }

  Future<void> mostrarNotificacion() async {
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'canal1',
        'Ubicaciones',
        importance: Importance.high,
      ),
    );

    await notifications.show(
      1,
      'Llegaste',
      'Has llegado a la librería seleccionada',
      detalles,
    );
  }

  Future<void> obtenerUbicacionActual() async {
    LocationData data = await location.getLocation();
    ubicacionActual = LatLng(data.latitude!, data.longitude!);

    setState(() {});
    escucharMovimientos();
  }

  void escucharMovimientos() {
    location.onLocationChanged.listen((loc) {
      ubicacionActual = LatLng(loc.latitude!, loc.longitude!);

      if (libreriaSeleccionada != null) {
        final distancia = calcularDistancia(
          ubicacionActual!.latitude,
          ubicacionActual!.longitude,
          libreriaSeleccionada!.latitude,
          libreriaSeleccionada!.longitude,
        );

        if (distancia < 50) {
          mostrarNotificacion();
        }
      }
    });
  }

  double calcularDistancia(double lat1, lng1, lat2, lng2) {
    const R = 6371000;
    double dLat = (lat2 - lat1) * (3.1415 / 180);
    double dLng = (lng2 - lng1) * (3.1415 / 180);
    double a =
        0.5 -
            (cos(lat2 * (3.1415 / 180)) *
                cos(lat1 * (3.1415 / 180)) *
                (1 - cos(dLng))) /
                2;
    return R * 2 * asin(sqrt(a));
  }

  Future<void> cargarLibreriasFirestore() async {
    final data = await FirebaseFirestore.instance.collection('librerias').get();

    for (var doc in data.docs) {
      final lat = doc['lat'];
      final lng = doc['lng'];
      final nombre = doc['nombre'];

      final markerId = MarkerId(doc.id);
      final marker = Marker(
        markerId: markerId,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: nombre),
        onTap: () {
          libreriaSeleccionada = LatLng(lat, lng);
          setState(() {});
        },
      );

      marcadores[markerId] = marker;
    }

    setState(() {});
  }

  void abrirRuta() {
    if (libreriaSeleccionada == null) return;

    final url =
        "https://www.google.com/maps/dir/?api=1&destination=${libreriaSeleccionada!.latitude},${libreriaSeleccionada!.longitude}";

    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de Librerías"),
        backgroundColor: Colors.blue,
      ),

      body: ubicacionActual == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: ubicacionActual!,
              zoom: 14,
            ),
            markers: Set<Marker>.of(marcadores.values),
            myLocationEnabled: true,
            onMapCreated: (controller) => mapaController = controller,
          ),

          if (libreriaSeleccionada != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(15),
                ),
                onPressed: abrirRuta,
                child: const Text(
                  "Seguir ruta",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
*/