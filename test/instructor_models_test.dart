import 'package:flutter_test/flutter_test.dart';
import 'package:sikarir/features/auth/data/models/auth_models.dart';
import 'package:sikarir/features/instructor/data/models/class_module_model.dart';

void main() {
  test('LoginResponse membaca role instruktur dan default peserta', () {
    final instruktur = LoginResponse.fromMap({
      'token': 't',
      'user': {'id': 1, 'name': 'Budi', 'email': 'b@x.id', 'role': 'Instruktur'},
    });
    expect(instruktur.isInstructor, isTrue);
    expect(LoginResponse.fromMap(instruktur.toMap()).isInstructor, isTrue);

    final peserta = LoginResponse.fromMap({
      'token': 't',
      'user': {'id': 2, 'name': 'Ani', 'email': 'a@x.id'},
    });
    expect(peserta.isInstructor, isFalse);
  });

  test('ClassModule mem-parsing materi file, link, dan teks', () {
    final module = ClassModule.fromMap({
      'id_modul': 5,
      'judul': 'Dasar HTML',
      'pertemuan_ke': '3',
      'materi': [
        {'id_materi': 1, 'judul': 'Slide', 'tipe': 'file', 'url': 'materi/a.pdf'},
        {'id_materi': 2, 'judul': 'Video', 'tipe': 'link', 'url': 'https://youtu.be/x'},
        {'id_materi': 3, 'judul': 'Catatan', 'tipe': 'teks', 'konten': 'Halo'},
      ],
    });
    expect(module.meetingNumber, 3);
    expect(module.materials.map((m) => m.kind), MaterialKind.values);
    expect(module.materials[0].url, endsWith('/storage/materi/a.pdf'));
    expect(module.materials[2].content, 'Halo');
  });
}
