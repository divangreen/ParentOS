import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ParentOS')),
      body: const Center(
        child: Text('S-004 scaffold — Riverpod + GoRouter + Material 3'),
      ),
    );
  }
}
