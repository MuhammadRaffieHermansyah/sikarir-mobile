# Rencana Pengerjaan Improvement SiKarir Mobile

Disusun 26 November 2026, berdasarkan kode di branch `feat/profile-update` (commit `c7b3c02`).

## Kondisi awal (baseline)

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter analyze` | 22 temuan: 1 warning, sisanya info (14 di antaranya di `tools/`) |
| `flutter test` | 63 lulus, 1 gagal (`partner_screen_test.dart`: overflow 7,5 px dan teks "0 Loker" tidak ditemukan) |
| Lupa kata sandi | **Palsu**: `login_page.dart` menampilkan "link telah dikirim" tanpa memanggil API |
| Token login | Disimpan di `SharedPreferences` (`auth_local_service.dart`) |
| Alamat server | IP lokal ditulis di `api_constants.dart`, HTTP |
| Penanganan 401 | Terpisah, terlihat di service presensi, sertifikat, dan akun |
| File kosong | `app/theme/*`, `core/network/*`, `secure_storage.dart`, sebagian `core/widgets/*`, `notification.dart` |
| Tema | Sudah ada di `core/constants/app_theme.dart`; `app/theme/*` hanya duplikat kosong |

## Prinsip kerja

- Satu tugas = satu branch dari `main` = satu PR, mengikuti format di `AGENTS.md`.
- Setiap PR wajib lolos `flutter analyze` dan `flutter test`.
- Refactor tidak mengubah perilaku, dan tidak digabung dengan fitur baru.
- Estimasi dalam hari kerja satu orang, masih kasar.

## Ringkasan fase

| Fase | Fokus | Estimasi | Butuh backend |
| --- | --- | --- | --- |
| 0 | Stabilisasi dan CI | 1–2 hari | Tidak |
| 1 | Keamanan dan jaringan | 4–6 hari | Sebagian |
| 2 | Tema, komponen, refactor | 6–9 hari | Tidak |
| 3 | UI/UX | 5–7 hari | Tidak |
| 4 | Fitur baru | 10–15 hari | Ya |

Total 26–39 hari kerja. Jika waktu terbatas (misalnya menjelang penilaian), kerjakan Fase 0, Fase 1, lalu tugas 3.1 dan 3.3.

---

## Fase 0: Stabilisasi dan CI

Tujuan: titik awal yang hijau sebelum mengubah banyak kode.

| ID | Tugas | Selesai bila | Hari |
| --- | --- | --- | --- |
| 0.1 | Selesaikan PR `feat/profile-update` ke `main` | Sudah di-merge | 0,5 |
| 0.2 | Perbaiki test partner yang gagal (overflow dan label loker) | Semua test lulus | 0,5 |
| 0.3 | Bereskan temuan analyze, hapus `_buildSocialCard` | `flutter analyze` 0 temuan | 0,5 |
| 0.4 | Tambah GitHub Actions: analyze dan test di tiap PR | Check muncul di PR | 0,5 |

**Uji E2E:** buka PR percobaan, pastikan CI berjalan. Buat satu test sengaja gagal, CI harus merah.

## Fase 1: Keamanan dan jaringan

| ID | Tugas | Selesai bila | Hari |
| --- | --- | --- | --- |
| 1.1 | `baseUrl` lewat `--dart-define=API_BASE_URL=...` | Ganti server tanpa edit kode | 0,5 |
| 1.2 | Token pindah ke `flutter_secure_storage`, dengan migrasi sesi lama | User lama tetap login, token hilang dari SharedPreferences | 1 |
| 1.3 | `ApiClient` di atas paket `http` yang sudah dipakai: header token, timeout, pemetaan error. Hapus stub Dio | Ada unit test untuk 200, 401, 422, 500, timeout | 1,5 |
| 1.4 | Migrasi service ke `ApiClient`, satu PR per fitur (auth, presensi dulu) | Tidak ada pemanggilan HTTP di luar `ApiClient` | 2 |
| 1.5 | Auto-logout terpusat saat 401 (403 tetap tidak logout, sesuai catatan di service presensi) | Token kedaluwarsa mengarah ke Login dengan pesan | 0,5 |
| 1.6 | Lupa kata sandi: **segera** ganti pesan palsu dengan arahan menghubungi admin; sambungkan ke API setelah endpoint tersedia | Tidak ada pesan sukses palsu | 0,5 |

Tugas 1.6 bagian pertama sebaiknya dikerjakan paling awal.

**Uji E2E**
1. Install versi lama, login, lalu update: sesi tetap aktif.
2. Cabut token di backend, buka halaman Presensi: kembali ke Login dengan pesan sesi habis.
3. Matikan server: muncul pesan error yang jelas dan tombol coba lagi, tanpa crash.
4. Login sebagai peserta dan instruktur: masuk ke beranda masing-masing.

## Fase 2: Tema, komponen, dan refactor

| ID | Tugas | Selesai bila | Hari |
| --- | --- | --- | --- |
| 2.1 | Satukan tema: pakai `core/constants/app_theme.dart` (boleh dipindah ke `app/theme`), hapus file kosong | Satu sumber tema | 0,5 |
| 2.2 | Ganti warna hardcode `Color(0x…)` dengan token warna | Hanya ada di file tema | 1 |
| 2.3 | Komponen bersama: tombol, text field, kartu, loading, error, empty state | Dipakai minimal di Home, Login, Pelatihan | 2 |
| 2.4 | Pecah `home.dart`, `training_detail_screen.dart`, `complete_profile_screen.dart` | Tiap file di bawah 400 baris | 3 |
| 2.5 | Pecah `partner_list_screen.dart`, `training_catalog_screen.dart`, `job_list_screen.dart` | Sama | 2 |
| 2.6 | Rapikan navigasi: semua rute bernama, rute tak dikenal tidak lagi jatuh ke Login | Tidak ada rute default menyesatkan | 0,5 |

**Uji E2E:** ambil screenshot tiap layar sebelum dan sesudah refactor, bandingkan. Jalankan alur login, daftar pelatihan, lengkapi profil, dan presensi: hasil sama seperti sebelumnya.

## Fase 3: UI/UX

| ID | Tugas | Selesai bila | Hari |
| --- | --- | --- | --- |
| 3.1 | State error, kosong, dan offline yang konsisten dengan "Coba lagi" | Semua layar daftar memakainya | 1,5 |
| 3.2 | `cached_network_image` dan skeleton loading | Tidak ada `Image.network` langsung | 1 |
| 3.3 | Presensi: pesan untuk GPS mati, izin ditolak (tombol ke Pengaturan), lokasi palsu | Tiap kondisi punya pesan dan tindakan | 1 |
| 3.4 | Lengkapi profil jadi wizard bertahap, draft tersimpan, persentase di Home | Keluar lalu masuk lagi, isian masih ada | 2 |
| 3.5 | Aksesibilitas: label semantik, area sentuh 48 dp, kontras, skala huruf | Tidak overflow pada skala huruf 1,5× | 1 |

Dark mode dan multi-bahasa ditunda sampai fase 2 selesai dan memang dibutuhkan.

**Uji E2E:** mode pesawat di tiap tab; tolak izin lokasi lalu aktifkan dari Pengaturan; isi setengah form profil, tutup aplikasi, buka lagi; navigasi dengan TalkBack.

## Fase 4: Fitur baru

Sepakati kontrak API lebih dulu (simpan di `docs/`), baru kerjakan mobile.

| Urutan | Fitur | Kebutuhan backend | Hari |
| --- | --- | --- | --- |
| 4.1 | Lupa kata sandi penuh (OTP atau tautan) | Endpoint reset dan email | 1–2 |
| 4.2 | Notifikasi: daftar dari API (ganti isi contoh yang statis di `main.dart`), lalu push FCM | Endpoint, simpan token perangkat, pengirim | 3–4 |
| 4.3 | Ringkasan kehadiran peserta dan rekap instruktur | Rekap; sebagian data mungkin sudah ada | 2–3 |
| 4.4 | Sertifikat: unduh, bagikan, verifikasi QR | URL file dan halaman verifikasi | 2–3 |
| 4.5 | Bookmark dan riwayat lamaran lowongan | Endpoint bookmark dan lamaran | 2–3 |

Cadangan (setelah semua di atas): mode offline, biometrik, pengumuman per kelas, rating pelatihan.

**Uji E2E**
1. Reset sandi lewat email, login dengan sandi baru, sandi lama ditolak.
2. Instruktur membuka sesi presensi, peserta menerima notifikasi, menyentuhnya membuka layar Presensi.
3. Unduh sertifikat, pindai QR, data cocok.

## Checklist tiap PR

- [ ] `flutter analyze` bersih
- [ ] `flutter test` lulus, ada test untuk logika baru
- [ ] Diuji di perangkat atau emulator, peran peserta dan instruktur bila terdampak
- [ ] Deskripsi PR dan skenario E2E sesuai `AGENTS.md`

## Risiko

| Risiko | Mitigasi |
| --- | --- |
| Endpoint backend belum siap | Fase 0–3 tidak bergantung padanya, kecuali 4.1 yang punya pengganti sementara (1.6) |
| Refactor memecahkan tampilan | PR kecil per layar, bandingkan screenshot |
| User lama ter-logout saat migrasi token | Test migrasi di tugas 1.2 |
| Konflik antar branch | Selesaikan 0.1 dulu, hindari dua orang di file yang sama |
