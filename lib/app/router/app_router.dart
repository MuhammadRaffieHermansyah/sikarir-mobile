import 'package:flutter/material.dart';
import 'package:sikarir/features/auth/presentation/pages/login_page.dart';
import 'package:sikarir/features/auth/presentation/pages/register_page.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return _materialRoute(const LoginScreen());
      case '/register':
        return _materialRoute(const RegisterScreen());
      default:
        return _materialRoute(const LoginScreen());
    }
  }

  static Route<dynamic> _materialRoute(Widget child) {
    return MaterialPageRoute(builder: (context) => child);
  }
}