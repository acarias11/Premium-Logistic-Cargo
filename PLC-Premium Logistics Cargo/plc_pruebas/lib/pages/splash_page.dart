import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () async {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        try {
          UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: args['email'],
            password: args['password'],
          );
          Navigator.of(context).pushReplacementNamed('/home');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            Navigator.of(context).pushReplacementNamed(
              '/signIn',
              arguments: 'No user found for that email.',
            );
          } else if (e.code == 'wrong-password') {
            Navigator.of(context).pushReplacementNamed(
              '/signIn',
              arguments: 'Wrong password provided.',
            );
          } else {
            Navigator.of(context).pushReplacementNamed(
              '/signIn',
              arguments: 'Authentication failed.',
            );
          }
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/signIn');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
