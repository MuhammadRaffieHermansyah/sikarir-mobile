import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/instructor/data/services/instructor_service.dart';
import 'package:sikarir/features/instructor/presentation/pages/instructor_navigation_screen.dart';
import 'package:sikarir/features/instructor/presentation/providers/instructor_provider.dart';
import 'package:sikarir/features/training/data/models/training_class_model.dart';

class _ServicePalsu extends InstructorService {
  int dipanggil = 0;

  @override
  Future<List<TrainingClassModel>> getTeachingClasses(String? token) async {
    dipanggil++;
    return [];
  }
}

void main() {
  testWidgets('Kelas kosong menjelaskan bahwa kelas muncul setelah ada peserta, dan bisa dimuat ulang', (tester) async {
    tester.view.physicalSize = const Size(1800, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final service = _ServicePalsu();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => InstructorProvider(service: service)),
        ],
        child: const MaterialApp(home: InstructorNavigationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('setelah ada peserta yang terdaftar'), findsOneWidget);
    expect(find.textContaining('belum ditugaskan mengampu kelas pelatihan mana pun'), findsNothing);

    final sebelum = service.dipanggil;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(service.dipanggil, sebelum + 1);
  });
}
