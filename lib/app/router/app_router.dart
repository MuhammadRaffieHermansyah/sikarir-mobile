import 'package:flutter/material.dart';
import 'package:sikarir/features/attendance/attendance.dart';
import 'package:sikarir/features/auth/auth.dart';
import 'package:sikarir/features/partner/partner.dart';
import 'package:sikarir/features/training/training.dart';
import 'package:sikarir/features/profile/presentation/pages/complete_profile_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return _materialRoute(const LoginScreen());
      case '/register':
        return _materialRoute(const RegisterScreen());
      case '/attendance':
        return _materialRoute(const AttendanceScreen());
      case '/classes':
        return _materialRoute(const MyClassesScreen());
      case '/schedules':
        return _materialRoute(const TrainingScheduleScreen());
      case '/partners':
        return _materialRoute(const PartnerListScreen());
      case '/complete-profile':
        return _materialRoute(const CompleteProfileScreen());
      default:
        return _materialRoute(const LoginScreen());
    }
  }

  static Route<dynamic> _materialRoute(Widget child) {
    return MaterialPageRoute(builder: (context) => child);
  }
}
