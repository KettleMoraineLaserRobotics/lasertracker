import 'package:material_ui/material_ui.dart';

class ErrorSnack {
  static void showErrorSnackBar(ScaffoldMessengerState scaffoldMessenger, Object error) {
    final message = error.toString().replaceFirst("Exception: ", "");
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text("Error: $message"), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16)),
    );
  }
}
