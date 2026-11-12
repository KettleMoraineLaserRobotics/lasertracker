import 'package:flutter/material.dart' as material;

class SnackBar {
  final String errorMessage;
  const SnackBar({required this.errorMessage});

  static void showErrorSnackBar(material.BuildContext context, String errorMessage) {
    material.ScaffoldMessenger.of(context).showSnackBar(material.SnackBar(content: material.Text(errorMessage)));
  }
}
