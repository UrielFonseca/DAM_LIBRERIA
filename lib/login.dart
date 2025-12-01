import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLogin = true;
  String mensaje = "";

  // Registrar usuario y guardar rol en Firestore
  Future<void> registrar() async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Lista de correos administradores
      const correosAdmin = [
        "admin@gmail.com",
        "biblioteca_admin@tuapp.com",
      ];

      final correo = emailController.text.trim();

      // Definir rol automático
      final rolAsignado = correosAdmin.contains(correo) ? "admin" : "usuario";

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'email': correo,
        'rol': rolAsignado,
      });

      setState(() {
        mensaje = " Usuario registrado.";
        isLogin = true;
      });
    } catch (e) {
      setState(() {
        mensaje = " Error: $e";
      });
    }
  }

  // Iniciar sesión y redirigir según rol
  Future<void> iniciarSesion() async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = cred.user!.uid;

      // Leer rol desde Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        setState(() {
          mensaje = "❌ Error: el usuario no existe en Firestore.";
        });
        return;
      }

      final rol = doc['rol'];

      if (rol == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/usuario');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          mensaje = "❌ Credenciales inválidas.";
        } else {
          mensaje = "❌ Error: ${e.message}";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Iniciar Sesión' : 'Registrar Usuario',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLogin ? 'Bienvenido de nuevo' : 'Crea tu cuenta',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                if (isLogin) {
                  iniciarSesion();
                } else {
                  registrar();
                }
              },
              child: Text(
                isLogin ? 'Iniciar sesión' : 'Registrar',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                  mensaje = "";
                });
              },
              child: Text(
                isLogin
                    ? '¿No tienes cuenta? Regístrate'
                    : '¿Ya tienes cuenta? Inicia sesión',
                style: const TextStyle(color: Colors.deepPurple),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mensaje.startsWith("✅")
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
