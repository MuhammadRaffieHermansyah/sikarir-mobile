# Kontrak API Update Profil (Peserta & Instruktur)

Acuan backend (Laravel) untuk fitur ubah profil di mobile. Semua endpoint di bawah `ApiConstants.baseUrl` (`/api`),
header `Accept: application/json` dan `Authorization: Bearer <token>`.

Prinsip:
- Profil selalu diambil dari **token** (`/me`), tidak ada `id` di URL, sehingga user tidak bisa mengubah profil orang lain.
- `role` dan `email` **tidak dapat diubah** lewat endpoint profil.
- Akun instruktur **dibuat oleh admin** (bukan daftar mandiri), lihat bagian 5.

Status: ✅ sudah dipakai mobile saat ini · 🆕 baru, perlu dibuat backend.

## 1. Akun (semua role)

### ✅ `GET /auth/me`
Mengembalikan akun yang login, wajib menyertakan `role`.

```json
{ "data": { "id": 7, "name": "Budi", "email": "budi@blk.id", "role": "instruktur",
            "foto": "foto/7.jpg", "must_change_password": false } }
```

### 🆕 `PUT /profile/password` — ganti password

| Field | Aturan |
|---|---|
| `password_lama` | wajib, harus cocok dengan password saat ini |
| `password_baru` | wajib, min. 8 karakter |
| `password_baru_confirmation` | wajib, sama dengan `password_baru` |

- Sukses `200` `{ "message": "Password berhasil diubah." }`; set `must_change_password = false`.
- Password lama salah → `422` dengan `errors.password_lama`.
- Disarankan mencabut token lain milik user setelah ganti password.

## 2. Profil Peserta

### ✅ `GET /pesertas/me`
Bentuk respons (`data` atau langsung objek):

`id_peserta`, `id_user`, `nomor_peserta`, `nama`, `jenis_kelamin`, `nomor_kk`, `nomor_wa`, `tanggal_lahir`,
`tempat_lahir`, `alamat_lengkap`, `pendidikan_terakhir`, `pendidikan_sekarang`, `status_pendidikan`
(`sudah_lulus` | `masih_menempuh`), `jurusan`, `pas_foto`, `is_disabilitas`, `jenis_disabilitas`, `is_profile_complete`.

### ✅ `POST /pesertas/me` — simpan / ubah profil
- Tanpa foto: JSON. Dengan foto: `multipart/form-data` (field file `pas_foto`; jpg/png/webp, maks 2 MB).
- Field yang dikirim sama dengan daftar di atas (kecuali `id_*`, `nomor_peserta`, `is_profile_complete`).
- Mobile juga mengirim `name` = `nama`; backend memperbarui `users.name` agar nama di akun ikut berubah.
- Respons `200/201`: objek profil terbaru.

**Perubahan yang diminta:** `nomor_peserta` dan `id_user` bersifat read-only (abaikan bila dikirim).

## 3. Profil Instruktur

### 🆕 `GET /instruktur/me`

```json
{ "data": {
    "id_instruktur": 3, "id_user": 7, "nama": "Budi Santoso", "email": "budi@blk.id",
    "nomor_wa": "08123456789", "bio": "Instruktur web dev 8 tahun.",
    "keahlian": "HTML, CSS, Laravel", "foto": "foto/7.jpg"
} }
```

### 🆕 `POST /instruktur/me` — ubah profil
`application/json` atau `multipart/form-data` bila ada foto.

| Field | Tipe | Aturan |
|---|---|---|
| `nama` | string | wajib, maks 100 (ikut memperbarui `users.name`) |
| `nomor_wa` | string | opsional, angka 8–15 digit |
| `bio` | string | opsional, maks 500 |
| `keahlian` | string | opsional, dipisah koma, maks 200 |
| `foto` | file | opsional, jpg/png/webp, maks 2 MB |

Respons `200`: objek profil terbaru (bentuk seperti `GET`). `email` & `role` diabaikan bila dikirim.

## 4. Format error

```json
{ "message": "The given data was invalid.", "errors": { "nomor_wa": ["Nomor WA tidak valid."] } }
```

Mobile menampilkan `message`; untuk `422` menampilkan pesan pertama dari `errors`. `401` → sesi berakhir, kembali ke login.

## 5. Pembuatan akun instruktur (rekomendasi untuk backend/admin)

1. Admin membuat akun lewat panel admin: `role = instruktur`, `must_change_password = true`.
2. Password sementara atau email undangan dengan link atur password.
3. Login pertama: bila `must_change_password = true`, mobile memaksa ke layar ganti password (`PUT /profile/password`).
4. Admin menugaskan instruktur ke kelas agar `/instruktur/kelas` hanya mengembalikan kelas miliknya.
5. Pendaftaran mandiri (`/auth/register`) selalu menghasilkan `role = peserta`; field `role` dari request diabaikan.

## 6. Ringkasan endpoint

| Method | Path | Role | Status |
|---|---|---|---|
| GET | `/auth/me` | semua | ✅ (tambah `role`, `foto`, `must_change_password`) |
| PUT | `/profile/password` | semua | 🆕 |
| GET | `/pesertas/me` | peserta | ✅ |
| POST | `/pesertas/me` | peserta | ✅ |
| GET | `/instruktur/me` | instruktur | 🆕 |
| POST | `/instruktur/me` | instruktur | 🆕 |
