import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sikarir/features/profile/data/models/instructor_profile_model.dart';
import 'package:sikarir/features/profile/data/services/account_service.dart';

void main() {
  test('InstructorProfile membaca data bersarang & daftar keahlian', () {
    final p = InstructorProfile.fromMap({
      'data': {
        'id_instruktur': 3,
        'nama': 'Budi',
        'email': 'budi@blk.id',
        'nomor_wa': '0812345678',
        'bio': 'Halo',
        'keahlian': 'HTML, Laravel , ',
        'foto': 'foto/7.jpg',
      },
    });
    expect(p.id, '3');
    expect(p.name, 'Budi');
    expect(p.expertiseList, ['HTML', 'Laravel']);
    expect(p.photoUrl, endsWith('/storage/foto/7.jpg'));
  });

  test('changePassword mengirim field kontrak & menampilkan error 422', () async {
    late http.Request captured;
    final service = AccountService(
      client: MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({
            'message': 'invalid',
            'errors': {
              'password_lama': ['Password lama salah.'],
            },
          }),
          422,
        );
      }),
    );

    await expectLater(
      service.changePassword(
        oldPassword: 'a',
        newPassword: 'password123',
        confirmation: 'password123',
        token: 't',
      ),
      throwsA(
        predicate((e) => e.toString().contains('Password lama salah.')),
      ),
    );
    expect(captured.method, 'PUT');
    expect(captured.headers['Authorization'], 'Bearer t');
    expect(jsonDecode(captured.body)['password_baru_confirmation'], 'password123');
  });

  test('getInstructorProfile mengembalikan null saat 404', () async {
    final service = AccountService(
      client: MockClient((_) async => http.Response('', 404)),
    );
    expect(await service.getInstructorProfile('t'), isNull);
  });
}
