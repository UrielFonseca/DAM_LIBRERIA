import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MapaLibrerias extends StatefulWidget {
  const MapaLibrerias({super.key});

  @override
  State<MapaLibrerias> createState() => _MapaLibreriasState();
}

class _MapaLibreriasState extends State<MapaLibrerias> {
  //MapController DE flutter_map
  final MapController mapaController = MapController();
  final double _proximityThresholdMeters = 100.0;

  Location location = Location();
  LatLng? ubicacionActual;

  //LIST<MARKER> DE flutter_map
  List<Marker> marcadores = [];
  LatLng? libreriaSeleccionada;
  bool _mapaListo = false;

  final FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    configurarNotificaciones();
    obtenerUbicacionActual();
    cargarLibreriasFirestore();
  }

  // Notificaciones y Ubicación
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
      '¡Alerta de Proximidad!',
      'Estás a menos de ${_proximityThresholdMeters}m de la librería seleccionada.',
      detalles,
    );
  }

  Future<void> obtenerUbicacionActual() async {
    LocationData data = await location.getLocation();
    ubicacionActual = LatLng(data.latitude!, data.longitude!);
    if (_mapaListo) {
      mapaController.move(ubicacionActual!, 14);
    }

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

        if (distancia < _proximityThresholdMeters) {
          print("🔥🔥 NOTIFICACION ENVIADA - Distancia: $distancia");
          mostrarNotificacion();
        }
      }

      if (_mapaListo && ubicacionActual != null) {
        mapaController.move(ubicacionActual!, mapaController.camera.zoom);
      }
      setState(() {});
    });
  }

  // Fórmula de Haversine para la distancia
  double calcularDistancia(double lat1, lng1, lat2, lng2) {
    const R = 6371000.0;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLng = (lng2 - lng1) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // Carga de Librerías y Marcadores
  Future<void> cargarLibreriasFirestore() async {
    final data = await FirebaseFirestore.instance.collection('librerias').get();

    List<Marker> nuevosMarcadores = [];

    for (var doc in data.docs) {
      // Usamos el nombre del campo exacto: 'Cordenadas'
      final GeoPoint? geoPoint = doc['Cordenadas'] as GeoPoint?;
      final nombre = doc['nombre'];
      // Si el GeoPoint es nulo
      if (geoPoint == null) {
        print('🚨 WARNING: La librería "${nombre ?? doc.id}" no tiene GeoPoint en el campo Cordenadas.');
        continue;
      }
      // Leemos las propiedades 'latitude' y 'longitude' del GeoPoint
      final lat = geoPoint.latitude;
      final lng = geoPoint.longitude;
      final latLng = LatLng(lat, lng);

      final marker = Marker(
        point: latLng,
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () {
            libreriaSeleccionada = latLng;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Librería seleccionada: $nombre")),
            );
            setState(() {});
          },
          child: const Column(
            children: [
              Icon(Icons.location_on, color: Colors.blue, size: 40),
            ],
          ),
        ),
      );

      nuevosMarcadores.add(marker);
    }
    setState(() {
      marcadores = nuevosMarcadores;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ubicacionActual == null) {
      return const Center(child: CircularProgressIndicator(value: null));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de Librerías"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapaController,
            options: MapOptions(
              initialCenter: ubicacionActual!,
              initialZoom: 14.0,
              onMapReady: () {
                setState(() {
                  _mapaListo = true;
                  mapaController.move(ubicacionActual!, 14.0);
                });
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.libros.biblioteca',
              ),

              // Marcador para la Ubicación Actual del Usuario
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: ubicacionActual!,
                    radius: 10,
                    color: Colors.blue.withOpacity(0.7),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 3,
                    useRadiusInMeter: true,
                  )
                ],
              ),
              //CAPA DE MARCADORES DE LIBRERÍAS
              MarkerLayer(markers: marcadores),
              //Círculo de proximidad de la librería seleccionada
              if (libreriaSeleccionada != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: libreriaSeleccionada!,
                      radius: _proximityThresholdMeters,
                      color: Colors.red.withOpacity(0.1),
                      borderColor: Colors.red,
                      borderStrokeWidth: 1,
                      useRadiusInMeter: true,
                    )
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}