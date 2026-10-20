import 'package:flutter/material.dart';

import 'screens/products_screen.dart';

void main() => runApp(const ProductStoreApp());

class ProductStoreApp extends StatelessWidget {
  const ProductStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const ProductsScreen(),
    );
  }
}
