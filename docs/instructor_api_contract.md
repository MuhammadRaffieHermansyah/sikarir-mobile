# Kontrak API Fitur Instruktur (Modul & Materi)

Dokumen ini menjadi acuan backend (Laravel) agar sesuai dengan implementasi mobile di `lib/features/instructor/`.
Semua endpoint berada di bawah `ApiConstants.baseUrl` (`/api`), memakai header `Accept: application/json` dan
`Authorization: Bearer <token>`.

## 1. Role pada login

`POST /auth/login` (dan `GET /auth/me` bila dipakai) harus menyertakan role pengguna.
Mobile membaca salah satu dari: `role`, `peran` pada root, `data`, atau `user`.

```json
{
  "token": "xxx",
  "user": { "id": 7, "name": "Budi", "email": "budi@blk.id", "role": "instruktur" }
}
```

- Nilai `instruktur` / `instructor` (tidak peka huruf besar-kecil) → antarmuka instruktur.
- Nilai lain / kosong → antarmuka peserta.

## 2. Kelas yang diampu

`GET /instruktur/kelas` — hanya untuk role instruktur; mengembalikan kelas milik instruktur login.

Respons: array, atau `{ "data": [...] }` / `{ "kelas": [...] }`. Bentuk tiap item sama dengan
`/kelas-pelatihan/me` (dipetakan oleh `TrainingClassModel.fromMap`): `id_kelas`, `id_jadwal`, `total_sesi`,
`jadwal.pelatihan.nama_pelatihan`, dst. `404` dianggap daftar kosong.

## 3. Modul per kelas

### Daftar modul (peserta & instruktur)

`GET /kelas-pelatihan/{id_kelas}/modul`

- Instruktur: hanya kelas yang ia ampu.
- Peserta: hanya kelas yang ia ikuti.

```json
{
  "data": [
    {
      "id_modul": 5,
      "id_kelas": 12,
      "judul": "Dasar HTML",
      "deskripsi": "Struktur halaman web",
      "pertemuan_ke": 1,
      "materi": [
        { "id_materi": 1, "id_modul": 5, "judul": "Slide HTML", "tipe": "file",
          "url": "materi/slide-html.pdf", "nama_file": "slide-html.pdf" },
        { "id_materi": 2, "id_modul": 5, "judul": "Video Pengantar", "tipe": "link",
          "url": "https://youtu.be/xxxx" },
        { "id_materi": 3, "id_modul": 5, "judul": "Catatan", "tipe": "teks",
          "konten": "Isi catatan..." }
      ]
    }
  ]
}
```

- `tipe`: `file` | `link` | `teks`.
- `url` untuk `file` boleh path relatif storage (mobile menambahkan `ApiConstants.storageUrl`) atau URL penuh.

### Tambah modul (instruktur pengampu)

`POST /kelas-pelatihan/{id_kelas}/modul` — JSON

| Field | Tipe | Aturan |
|---|---|---|
| `judul` | string | wajib |
| `deskripsi` | string | opsional |
| `pertemuan_ke` | integer | wajib, ≥ 1 |

Respons sukses `200/201`, body boleh berisi modul baru (`{ "data": {...} }`).

### Hapus modul

`DELETE /modul/{id_modul}` → `200` atau `204`. Materi di dalamnya ikut terhapus.

## 4. Materi

### Tambah materi

`POST /modul/{id_modul}/materi` — `multipart/form-data`

| Field | Dikirim bila | Aturan |
|---|---|---|
| `judul` | selalu | wajib |
| `tipe` | selalu | `file` / `link` / `teks` |
| `file` | `tipe=file` | wajib; pdf, doc(x), ppt(x), xls(x), zip, mp4, jpg, png |
| `url` | `tipe=link` | wajib, URL http/https |
| `konten` | `tipe=teks` | wajib |

Respons sukses `200/201`. Disarankan batas ukuran file dan `nama_file` ikut dikembalikan.

### Hapus materi

`DELETE /materi/{id_materi}` → `200` atau `204`.

## 5. Format error

Mobile menampilkan `message`; untuk validasi Laravel (`422`) ditampilkan pesan error pertama dari `errors`.

```json
{ "message": "The given data was invalid.", "errors": { "judul": ["Judul wajib diisi."] } }
```

## 6. Otorisasi (sisi backend)

- Endpoint tulis (`POST`/`DELETE` modul & materi) hanya untuk instruktur yang mengampu kelas terkait → `403` bila bukan.
- Endpoint baca modul: instruktur pengampu atau peserta terdaftar kelas tersebut.
