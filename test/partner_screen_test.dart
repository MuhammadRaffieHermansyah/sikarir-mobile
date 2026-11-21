import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sikarir/features/auth/presentation/providers/auth_provider.dart';
import 'package:sikarir/features/partner/data/models/partner_model.dart';
import 'package:sikarir/features/partner/data/repositories/partner_repository.dart';
import 'package:sikarir/features/partner/presentation/pages/partner_list_screen.dart';
import 'package:sikarir/features/partner/presentation/providers/partner_provider.dart';

class MockPartnerRepository implements PartnerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<PartnerModel>> getPartners([String? token]) async {
    return [
      PartnerModel(
        id: '1',
        name: 'PT Sangat Panjang Sekali Nama Perusahaan Kemitraan Industri Nasional Indonesia Tbk',
        industry: 'Fintech, Artificial Intelligence & Heavy Industrial Software Development',
        logo: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=100&auto=format&fit=crop&q=80',
        location: 'Kawasan Industri MM2100, Blok C-99, Cikarang Barat, Kabupaten Bekasi, Provinsi Jawa Barat, 17530',
        description: 'Perusahaan payment gateway terbesar di Asia Tenggara yang bermitra dengan BLK untuk penyerapan talent lulusan IT.',
        activeVacancies: 12,
        partnershipType: 'Penyalur Tenaga Kerja Resmi & Asesor Uji Kompetensi Magang OJT',
        website: 'https://midtrans.com',
      ),
      PartnerModel(
        id: '2',
        name: 'PT Astra Daihatsu Motor',
        industry: 'Manufaktur & Otomotif',
        logo: 'https://images.unsplash.com/photo-1549923746-c502d488b3ea?w=100&auto=format&fit=crop&q=80',
        location: 'Sunter, Jakarta Utara',
        description: 'Pabrikan otomotif nasional.',
        activeVacancies: 0,
        partnershipType: 'Tempat Magang OJT',
        website: 'https://daihatsu.co.id',
      ),
    ];
  }
}

void main() {
  testWidgets('PartnerListScreen renders without overflow even with extremely long strings', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockPartnerRepository();
    final partnerProvider = PartnerProvider(repository: mockRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<PartnerProvider>.value(value: partnerProvider),
        ],
        child: const MaterialApp(
          home: PartnerListScreen(),
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify screen title
    expect(find.text('Mitra Industri & Perusahaan'), findsOneWidget);

    // Verify long company name exists without crashing or overflowing
    expect(find.textContaining('PT Sangat Panjang'), findsOneWidget);

    // Verify Loker badges
    expect(find.text('12 Loker'), findsOneWidget);
    expect(find.text('0 Loker'), findsOneWidget);

    // Verify search interaction
    await tester.enterText(find.byType(TextField), 'Daihatsu');
    await tester.pumpAndSettle();

    expect(find.text('PT Astra Daihatsu Motor'), findsOneWidget);
    expect(find.textContaining('PT Sangat Panjang'), findsNothing);

    // Tap partner card to open detail sheet
    await tester.tap(find.text('PT Astra Daihatsu Motor'));
    await tester.pumpAndSettle();

    expect(find.text('Tentang Kemitraan'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);

    // Close sheet
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
  });
}
