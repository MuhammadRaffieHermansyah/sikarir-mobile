# Kontrak API — Sesi Presensi (dikontrol instruktur)

Dokumen ini adalah kontrak yang **dipakai aplikasi Flutter SiKarir** saat ini
(`InstructorService`, `AttendanceService`). Backend (Laravel) perlu menyediakan
tabel, route, dan controller berikut. Semua endpoint di bawah `ApiConstants.baseUrl`
(`/api`), memakai `Authorization: Bearer <token>` dan `Accept: application/json`.

## 1. Konsep

Instruktur membuat **sesi presensi** per pertemuan sebuah kelas, lalu
**membuka/menutup** presensinya. Peserta hanya bisa presensi masuk (hadir) saat
ada sesi yang sedang dibuka. Izin/sakit tidak bergantung pada sesi.
Aplikasi hanya memakai presensi **masuk**; tidak ada presensi pulang.

## 2. Tabel `sesi_presensi`

| Kolom | Tipe | Catatan |
|---|---|---|
| `id_sesi` | bigint PK | |
| `id_jadwal` | FK → `jadwal_pelatihan` | `cascadeOnDelete`; sesi berlaku untuk semua peserta jadwal itu (seperti modul). Endpoint tetap memakai `id_kelas` lalu di-resolve ke jadwal |
| `id_instruktur` | FK | pembuat sesi |
| `pertemuan_ke` | unsigned int | unik per `id_kelas` |
| `tanggal` | date | |
| `jam_mulai` | time | |
| `jam_selesai` | time | harus > `jam_mulai` |
| `lokasi_latitude` | decimal(10,7) nullable | null → pakai titik jadwal/default |
| `lokasi_longitude` | decimal(10,7) nullable | |
| `radius_meter` | unsigned int | default 100 |
| `absen_dibuka` | boolean | **default `false`** |
| timestamps | | |

Unique index: (`id_jadwal`, `pertemuan_ke`).

> Status: sudah diimplementasikan di `sikarir-web` (`SesiPresensiController`,
> migrasi `2026_11_26_000001_create_sesi_presensi_table`, tes `SesiPresensiTest`).

Tabel `absen` perlu kolom baru `id_sesi` (nullable FK → `sesi_presensi`) dan unique
(`id_peserta`, `id_sesi`) agar satu peserta tak bisa hadir dua kali di sesi yang sama.

## 3. Endpoint instruktur

Middleware: `auth:sanctum` + role instruktur. Instruktur **harus pengampu kelas
tersebut**, jika bukan → `403`.

### 3.1 `GET /kelas-pelatihan/{id_kelas}/sesi-presensi`
Daftar sesi satu kelas (urut `pertemuan_ke`). Kelas tanpa sesi → `200` + `data: []`
(404 juga ditoleransi aplikasi).

```json
{
  "data": [
    {
      "id_sesi": 12,
      "id_kelas": 3,
      "pertemuan_ke": 1,
      "tanggal": "2026-11-26",
      "jam_mulai": "08:00",
      "jam_selesai": "15:00",
      "lokasi_latitude": -8.15753,
      "lokasi_longitude": 113.7229492,
      "radius_meter": 100,
      "absen_dibuka": true,
      "jumlah_hadir": 14
    }
  ]
}
```

Catatan format: `jam_*` boleh `HH:mm` atau `HH:mm:ss` (aplikasi memotong 5 karakter);
`tanggal` boleh `Y-m-d` atau ISO (aplikasi memotong di `T`); `absen_dibuka` boolean;
`jumlah_hadir` = jumlah `absen` berstatus `hadir` pada sesi itu.

### 3.2 `POST /kelas-pelatihan/{id_kelas}/sesi-presensi`
Body JSON:

```json
{
  "pertemuan_ke": 1,
  "tanggal": "2026-11-26",
  "jam_mulai": "08:00",
  "jam_selesai": "15:00",
  "lokasi_latitude": -8.15753,
  "lokasi_longitude": 113.7229492,
  "radius_meter": 100
}
```

`lokasi_latitude`/`lokasi_longitude` opsional (keduanya diisi atau keduanya tidak ada).

Validasi:
- `pertemuan_ke`: required, integer, min 1, unik per kelas
- `tanggal`: required, `Y-m-d`, tidak boleh sebelum hari ini
- `jam_mulai`, `jam_selesai`: required, `H:i`; `jam_selesai` after `jam_mulai`
- `lokasi_latitude`: nullable, between -90..90; `lokasi_longitude`: nullable, between -180..180
- `radius_meter`: required, integer, 10..5000

Sukses → `201` `{ "message": "...", "data": { …objek sesi seperti 3.1… } }`
dengan `absen_dibuka = false`.

### 3.3 `PATCH /sesi-presensi/{id_sesi}`
Buka/tutup presensi.

```json
{ "absen_dibuka": true }
```
Sukses → `200` `{ "message": "...", "data": { …sesi… } }`.
Aturan: saat membuka, tolak (`422`) jika `tanggal` sesi sudah lewat.

### 3.4 `DELETE /sesi-presensi/{id_sesi}`
Sukses → `200` atau `204`. Jika sesi sudah punya data `absen`, boleh ditolak
dengan `422` ("Sesi sudah memiliki data kehadiran") atau di-cascade — pilih salah satu
dan konsisten.

## 4. Endpoint peserta

### 4.1 `GET /kelas-pelatihan/{id_kelas}/sesi-presensi/aktif`
Sesi yang **sedang dibuka** untuk kelas itu. Peserta harus terdaftar di kelas.

Kriteria "aktif": `absen_dibuka = true` **dan** `tanggal = hari ini`
(opsional: jam sekarang di antara `jam_mulai` dan `jam_selesai`). Jika ada lebih dari
satu, ambil `pertemuan_ke` terbesar.

- Ada → `200` `{ "data": { …objek sesi seperti 3.1… } }`
- Tidak ada → `404` (aplikasi menganggap "presensi belum dibuka")

Aplikasi juga memeriksa `absen_dibuka == true` di respons; sesi tertutup diabaikan.

### 4.2 `POST /absen` (perubahan endpoint yang sudah ada)
Body kini boleh memuat `id_sesi` (hanya dikirim untuk presensi **hadir**):

```json
{
  "id_sesi": 12,
  "id_jadwal": 5,
  "id_peserta": 9,
  "tanggal": "2026-11-26",
  "jam_hadir": "08:07:00",
  "status_kehadiran": "hadir",
  "latitude": -8.1576,
  "longitude": 113.7230
}
```

Tambahan validasi jika `status_kehadiran = hadir`:
1. `id_sesi` **wajib** bila jadwal sudah punya sesi presensi (jadwal tanpa sesi sama
   sekali tetap memakai perilaku lama); sesi harus ada dan milik `id_jadwal` → jika tidak `422`.
2. `absen_dibuka` harus `true` dan `tanggal` sesi = hari ini (+ jam di rentang jika dipakai)
   → jika tidak `403` dengan pesan, mis. `"Presensi belum dibuka oleh instruktur."`.
3. Jarak (`latitude`,`longitude`) dihitung terhadap `lokasi_latitude/longitude` **sesi**;
   jika null, pakai titik jadwal, lalu default BLK. Radius = `radius_meter` sesi.
   Di luar radius → `403` dengan pesan jarak (perilaku saat ini).
4. Satu peserta satu kali per sesi → `422` jika duplikat.

`izin`/`sakit` tidak memerlukan `id_sesi` dan perilaku lamanya tidak berubah.

## 5. Format error (dibaca aplikasi)

```json
{ "message": "Pesan ringkas", "errors": { "field": ["Pesan validasi pertama"] } }
```

Aplikasi menampilkan `errors` pertama bila ada, jika tidak `message`.

| Kode | Arti |
|---|---|
| 401 | sesi/token habis → aplikasi minta login ulang |
| 403 | bukan pengampu / presensi belum dibuka / di luar radius (**dengan `message`**) |
| 404 | kelas/sesi tak ditemukan; pada 4.1 berarti "tidak ada sesi aktif" |
| 422 | validasi gagal |

## 6. Kerangka Laravel

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    // instruktur
    Route::middleware('role:instruktur')->group(function () {
        Route::get   ('kelas-pelatihan/{kelas}/sesi-presensi', [SesiPresensiController::class, 'index']);
        Route::post  ('kelas-pelatihan/{kelas}/sesi-presensi', [SesiPresensiController::class, 'store']);
        Route::patch ('sesi-presensi/{sesi}',                  [SesiPresensiController::class, 'update']);
        Route::delete('sesi-presensi/{sesi}',                  [SesiPresensiController::class, 'destroy']);
    });
    // peserta
    Route::get('kelas-pelatihan/{kelas}/sesi-presensi/aktif', [SesiPresensiController::class, 'aktif']);
});
```

`SesiPresensiController`: `index`, `store`, `update` (toggle `absen_dibuka`),
`destroy` (cek pengampu via policy), `aktif` (query: `where absen_dibuka, whereDate tanggal today`,
cek peserta terdaftar). Ubah `AbsenController@store` sesuai 4.2.

> Urutan route: daftarkan `.../sesi-presensi/aktif` sebelum route berparameter lain
> pada prefix yang sama agar tidak tertangkap sebagai `{sesi}`.

## 7. Checklist pengujian backend

- [ ] Instruktur pengampu bisa membuat, membuka, menutup, menghapus sesi; instruktur lain → 403
- [ ] `pertemuan_ke` ganda pada kelas yang sama → 422
- [ ] Sesi baru `absen_dibuka=false`; `GET .../aktif` → 404
- [ ] Setelah dibuka (tanggal hari ini) `GET .../aktif` → 200 dengan sesi tersebut
- [ ] Peserta kelas lain memanggil `.../aktif` → 403/404
- [ ] `POST /absen` hadir tanpa `id_sesi` → 422; saat sesi tertutup → 403
- [ ] `POST /absen` hadir di luar radius sesi → 403 dengan pesan jarak; dalam radius → 201
- [ ] Hadir dua kali di sesi sama → 422
- [ ] `jumlah_hadir` di daftar sesi bertambah setelah peserta hadir
- [ ] Izin/sakit tetap bisa diajukan tanpa sesi
