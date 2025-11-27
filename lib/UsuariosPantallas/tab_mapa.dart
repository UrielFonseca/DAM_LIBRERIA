import 'package:flutter/material.dart';

class TabMapa extends StatelessWidget {
  const TabMapa({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 80, color: Colors.grey),
          Text("Módulo de Mapa", style: TextStyle(fontSize: 20, color: Colors.grey)),
          Text("(A cargo de otro integrante)", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
