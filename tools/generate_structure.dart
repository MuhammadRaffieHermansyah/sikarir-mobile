import 'dart:io';

void main() {
  const directories = [
    // APP
    'lib/app',
    'lib/app/router',
    'lib/app/theme',

    // CORE
    'lib/core',
    'lib/core/network',
    'lib/core/storage',
    'lib/core/constants',
    'lib/core/utils',
    'lib/core/errors',
    'lib/core/widgets',

    // FEATURES - AUTH
    'lib/features/auth/data',
    'lib/features/auth/data/models',
    'lib/features/auth/data/repositories',
    'lib/features/auth/data/services',
    'lib/features/auth/presentation',
    'lib/features/auth/presentation/pages',
    'lib/features/auth/presentation/providers',
    'lib/features/auth/presentation/widgets',

    // FEATURES - HOME
    'lib/features/home/data',
    'lib/features/home/data/models',
    'lib/features/home/data/repositories',
    'lib/features/home/data/services',
    'lib/features/home/presentation',
    'lib/features/home/presentation/pages',
    'lib/features/home/presentation/providers',
    'lib/features/home/presentation/widgets',

    // FEATURES - TRAINING
    'lib/features/training/data',
    'lib/features/training/data/models',
    'lib/features/training/data/repositories',
    'lib/features/training/data/services',
    'lib/features/training/presentation',
    'lib/features/training/presentation/pages',
    'lib/features/training/presentation/providers',
    'lib/features/training/presentation/widgets',

    // FEATURES - ATTENDANCE
    'lib/features/attendance/data',
    'lib/features/attendance/data/models',
    'lib/features/attendance/data/repositories',
    'lib/features/attendance/data/services',
    'lib/features/attendance/presentation',
    'lib/features/attendance/presentation/pages',
    'lib/features/attendance/presentation/providers',
    'lib/features/attendance/presentation/widgets',

    // FEATURES - CERTIFICATE
    'lib/features/certificate/data',
    'lib/features/certificate/data/models',
    'lib/features/certificate/data/repositories',
    'lib/features/certificate/data/services',
    'lib/features/certificate/presentation',
    'lib/features/certificate/presentation/pages',
    'lib/features/certificate/presentation/providers',
    'lib/features/certificate/presentation/widgets',

    // FEATURES - JOB
    'lib/features/job/data',
    'lib/features/job/data/models',
    'lib/features/job/data/repositories',
    'lib/features/job/data/services',
    'lib/features/job/presentation',
    'lib/features/job/presentation/pages',
    'lib/features/job/presentation/providers',
    'lib/features/job/presentation/widgets',

    // FEATURES - PROFILE
    'lib/features/profile/data',
    'lib/features/profile/data/models',
    'lib/features/profile/data/repositories',
    'lib/features/profile/data/services',
    'lib/features/profile/presentation',
    'lib/features/profile/presentation/pages',
    'lib/features/profile/presentation/providers',
    'lib/features/profile/presentation/widgets',

    // FEATURES - NOTIFICATION
    'lib/features/notification/data',
    'lib/features/notification/data/models',
    'lib/features/notification/data/repositories',
    'lib/features/notification/data/services',
    'lib/features/notification/presentation',
    'lib/features/notification/presentation/pages',
    'lib/features/notification/presentation/providers',
    'lib/features/notification/presentation/widgets',
  ];

  const files = {
    // APP
    'lib/app/app.dart': '''
import 'package:flutter/material.dart';

class SikarirApp extends StatelessWidget {
  const SikarirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIKARIR',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('SIKARIR'),
        ),
      ),
    );
  }
}
''',

    'lib/app/router/app_router.dart': '''
// Application routes will be configured here.
''',

    'lib/app/theme/app_theme.dart': '''
// Application theme configuration.
''',

    'lib/app/theme/app_colors.dart': '''
// Application color palette.
''',

    'lib/app/theme/app_text_styles.dart': '''
// Application text styles.
''',

    // CORE
    'lib/core/network/dio_client.dart': '''
// Dio client configuration.
''',

    'lib/core/network/api_interceptor.dart': '''
// API interceptor configuration.
''',

    'lib/core/storage/secure_storage.dart': '''
// Secure storage configuration.
''',

    'lib/core/constants/api_constants.dart': '''
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:8000/api';
}
''',

    'lib/core/constants/app_constants.dart': '''
class AppConstants {
  AppConstants._();

  static const String appName = 'SIKARIR';
}
''',

    'lib/core/utils/helpers.dart': '''
// Helper functions.
''',

    'lib/core/utils/formatter.dart': '''
// Formatter functions.
''',

    'lib/core/errors/failures.dart': '''
// Application failure definitions.
''',

    'lib/core/widgets/app_button.dart': '''
// Reusable application button.
''',

    'lib/core/widgets/app_text_field.dart': '''
// Reusable application text field.
''',

    'lib/core/widgets/loading_widget.dart': '''
// Reusable loading widget.
''',

    // FEATURE PLACEHOLDERS
    'lib/features/auth/auth.dart': '''
export 'presentation/pages/login_page.dart';
export 'presentation/pages/register_page.dart';
''',

    'lib/features/home/home.dart': '''
// Home feature exports.
''',

    'lib/features/training/training.dart': '''
// Training feature exports.
''',

    'lib/features/attendance/attendance.dart': '''
// Attendance feature exports.
''',

    'lib/features/certificate/certificate.dart': '''
// Certificate feature exports.
''',

    'lib/features/job/job.dart': '''
// Job feature exports.
''',

    'lib/features/profile/profile.dart': '''
// Profile feature exports.
''',

    'lib/features/notification/notification.dart': '''
// Notification feature exports.
''',
  };

  print('');
  print('🚀 Generating SIKARIR Flutter Architecture...');
  print('');

  for (final path in directories) {
    final directory = Directory(path);

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      print('📁 Created: $path');
    } else {
      print('⏭️  Exists:  $path');
    }
  }

  print('');
  print('Creating starter files...');
  print('');

  files.forEach((path, content) {
    final file = File(path);

    if (!file.existsSync()) {
      file.createSync(recursive: true);
      file.writeAsStringSync(content.trim());
      print('📄 Created: $path');
    } else {
      print('⏭️  Exists:  $path');
    }
  });

  print('');
  print('✅ SIKARIR Flutter architecture generated successfully!');
  print('');
}