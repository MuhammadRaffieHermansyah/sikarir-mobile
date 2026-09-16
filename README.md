# SIKARIR Mobile

## Sistem Informasi Pelatihan dan Karier Terintegrasi

SIKARIR Mobile adalah aplikasi mobile berbasis Flutter yang menjadi bagian dari ekosistem **SIKARIR (Sistem Informasi Pelatihan dan Karier Terintegrasi)**.

Aplikasi ini dirancang untuk membantu peserta pelatihan dan pencari kerja dalam mengakses informasi pelatihan, melakukan pendaftaran pelatihan, melihat jadwal, melakukan presensi, mengakses sertifikat, serta menemukan peluang pekerjaan.

Backend dan sistem administrasi SIKARIR dibangun menggunakan Laravel REST API.

---

# Tujuan Aplikasi

SIKARIR menghubungkan beberapa pihak dalam satu ekosistem:

* Peserta pelatihan
* Pencari kerja
* Balai Latihan Kerja (BLK)
* Disnaker
* Perusahaan mitra

Alur utama sistem:

```text
Peserta
   ↓
Mencari Pelatihan
   ↓
Mendaftar Pelatihan
   ↓
Mengikuti Pelatihan
   ↓
Mendapatkan Kompetensi
   ↓
Mendapatkan Sertifikat
   ↓
Mencari Lowongan
   ↓
Melamar Pekerjaan
```

---

# Tech Stack

## Mobile

* Flutter
* Dart

## State Management

* Riverpod

## Networking

* Dio

## Routing

* GoRouter

## Backend

* Laravel REST API
* Laravel Sanctum

## Database

* MySQL atau PostgreSQL

## Storage

* Flutter Secure Storage
* Shared Preferences

---

# Project Architecture

Project ini menggunakan pendekatan:

> Feature-First Architecture + Repository Pattern

Setiap fitur memiliki folder sendiri sehingga kode yang berkaitan dengan fitur tersebut tetap terorganisir.

Struktur utama:

```text
lib/
├── app/
├── core/
├── features/
└── main.dart
```

---

# Folder Structure

```text
lib/
│
├── app/
│   ├── app.dart
│   │
│   ├── router/
│   │   └── app_router.dart
│   │
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_text_styles.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── training/
│   ├── attendance/
│   ├── certificate/
│   ├── job/
│   ├── profile/
│   └── notification/
│
└── main.dart
```

---

# APP

Folder `app` digunakan untuk konfigurasi global aplikasi.

```text
app/
├── app.dart
├── router/
└── theme/
```

## app.dart

Merupakan root widget aplikasi.

Contoh:

```dart
MaterialApp.router(
  routerConfig: appRouter,
);
```

---

## router

Digunakan untuk mengatur navigasi aplikasi.

Contoh:

```text
/login
/home
/trainings
/jobs
/profile
```

Routing direkomendasikan menggunakan GoRouter.

---

## theme

Berisi konfigurasi visual aplikasi.

```text
theme/
├── app_theme.dart
├── app_colors.dart
└── app_text_styles.dart
```

### app_colors.dart

Berisi warna utama aplikasi.

Contoh:

```dart
class AppColors {
  static const primary = Color(0xFF1E3A8A);
}
```

### app_text_styles.dart

Berisi konfigurasi typography.

### app_theme.dart

Berisi konfigurasi Light Theme dan Dark Theme aplikasi.

---

# CORE

Folder `core` berisi kode yang dapat digunakan oleh seluruh fitur.

```text
core/
├── constants/
├── errors/
├── network/
├── storage/
├── utils/
└── widgets/
```

Kode dalam `core` tidak boleh terlalu spesifik terhadap satu fitur.

Contoh:

```text
app_button.dart
```

dapat digunakan oleh:

```text
auth
training
job
profile
```

---

# NETWORK

Folder:

```text
core/network/
```

Berisi konfigurasi komunikasi dengan Laravel API.

Contoh:

```text
dio_client.dart
api_interceptor.dart
```

Arsitektur:

```text
Flutter
   ↓
Dio
   ↓
Laravel REST API
   ↓
Database
```

---

# STORAGE

Folder:

```text
core/storage/
```

Digunakan untuk menyimpan data lokal.

Contoh data:

* Authentication token
* User session
* User preferences

Untuk token authentication direkomendasikan menggunakan:

```text
Flutter Secure Storage
```

---

# FEATURES

Folder `features` merupakan bagian utama aplikasi.

Setiap fitur memiliki struktur masing-masing.

Contoh:

```text
features/
├── auth/
├── training/
├── job/
└── profile/
```

---

# Feature Architecture

Setiap feature menggunakan struktur:

```text
feature/
├── data/
└── presentation/
```

Contoh:

```text
training/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
│
└── presentation/
    ├── pages/
    ├── providers/
    └── widgets/
```

---

# DATA

Folder `data` menangani data dan komunikasi dengan API.

```text
data/
├── models/
├── repositories/
└── services/
```

## Models

Digunakan untuk merepresentasikan data.

Contoh:

```text
training_model.dart
```

Model bertanggung jawab melakukan parsing data dari API.

```text
JSON
 ↓
Model
 ↓
Flutter Object
```

---

## Services

Service bertugas melakukan request API.

Contoh:

```text
GET /api/trainings
```

File:

```text
training_service.dart
```

Alur:

```text
Service
   ↓
Dio
   ↓
Laravel API
```

---

## Repositories

Repository menjadi penghubung antara state management dan API service.

Alur:

```text
Provider
   ↓
Repository
   ↓
Service
   ↓
API
```

Repository membantu memisahkan UI dari komunikasi API.

---

# PRESENTATION

Folder `presentation` menangani tampilan aplikasi dan state management.

```text
presentation/
├── pages/
├── providers/
└── widgets/
```

---

## Pages

Berisi halaman aplikasi.

Contoh:

```text
login_page.dart
register_page.dart

training_page.dart
training_detail_page.dart

job_page.dart
job_detail_page.dart

profile_page.dart
```

---

## Providers

Digunakan untuk state management menggunakan Riverpod.

Contoh:

```text
training_provider.dart
```

Alur:

```text
UI
 ↓
Riverpod Provider
 ↓
Repository
 ↓
Service
 ↓
Laravel API
```

---

## Widgets

Widget khusus untuk feature tertentu.

Contoh:

```text
training_card.dart
```

Widget tersebut hanya digunakan oleh fitur training.

Sedangkan widget yang dapat digunakan oleh semua feature ditempatkan di:

```text
core/widgets/
```

---

# Application Features

## Authentication

```text
features/auth/
```

Fitur:

* Login
* Register
* Logout
* Session Management
* Token Management

---

# Home

```text
features/home/
```

Menampilkan dashboard utama pengguna.

Contoh informasi:

* Pelatihan aktif
* Pelatihan rekomendasi
* Jadwal terdekat
* Lowongan pekerjaan

---

# Training

```text
features/training/
```

Fitur:

* Daftar pelatihan
* Detail pelatihan
* Jadwal pelatihan
* Pendaftaran pelatihan
* Status pendaftaran
* Riwayat pelatihan

---

# Attendance

```text
features/attendance/
```

Fitur:

* Presensi
* QR Code Attendance
* Riwayat presensi

---

# Certificate

```text
features/certificate/
```

Fitur:

* Daftar sertifikat
* Detail sertifikat
* QR Verification
* Digital Certificate

---

# Job

```text
features/job/
```

Fitur:

* Daftar lowongan
* Detail lowongan
* Pencarian lowongan
* Job Application
* Riwayat lamaran

---

# Profile

```text
features/profile/
```

Fitur:

* Informasi pengguna
* Skill
* Riwayat pelatihan
* Sertifikat
* Skill Passport

---

# Notification

```text
features/notification/
```

Fitur:

* Notifikasi pelatihan
* Notifikasi status pendaftaran
* Notifikasi lowongan
* Push notification

---

# Data Flow

Arsitektur komunikasi data:

```text
Flutter Page
      ↓
Riverpod Provider
      ↓
Repository
      ↓
Service
      ↓
Dio Client
      ↓
Laravel REST API
      ↓
Database
```

Contoh:

```text
TrainingPage
      ↓
TrainingProvider
      ↓
TrainingRepository
      ↓
TrainingService
      ↓
GET /api/trainings
```

---

# Generate Folder Structure

Project menyediakan CLI sederhana untuk membuat struktur folder awal.

File:

```text
tool/generate_structure.dart
```

Jalankan:

```bash
dart run tool/generate_structure.dart
```

CLI akan membuat folder:

```text
app
core
features
```

beserta struktur dasar setiap feature.

CLI aman dijalankan berulang kali karena folder dan file yang sudah ada tidak akan ditimpa.

---

# Recommended Dependencies

Tambahkan dependency berikut:

```yaml
dependencies:
  flutter:
    sdk: flutter

  flutter_riverpod: ^3.0.0
  go_router: ^17.0.0
  dio: ^5.9.0
  flutter_secure_storage: ^10.0.0
  shared_preferences: ^2.5.0
  intl: ^0.20.0
  flutter_svg: ^2.2.0
  cached_network_image: ^3.4.0
```

Versi package dapat disesuaikan dengan versi Flutter SDK yang digunakan.

---

# Coding Principles

Project menggunakan beberapa prinsip berikut:

1. Setiap feature berdiri sendiri.
2. UI tidak melakukan request API secara langsung.
3. API request dilakukan melalui Service.
4. Provider tidak berkomunikasi langsung dengan Dio.
5. Repository menjadi abstraction layer antara state dan API.
6. Widget reusable ditempatkan di `core/widgets`.
7. Widget khusus feature ditempatkan di feature masing-masing.
8. Constants tidak ditulis secara hardcode berulang kali.
9. Authentication token disimpan menggunakan Secure Storage.

---

# Future Architecture

Untuk pengembangan berikutnya, sistem dapat ditambahkan:

```text
AI Training Recommendation

Job Matching

QR Attendance

Digital Certificate

Push Notification

Skill Passport

Career Analytics
```

---

# Development Workflow

Ketika membuat fitur baru:

```text
1. Buat Feature
       ↓
2. Buat Model
       ↓
3. Buat API Service
       ↓
4. Buat Repository
       ↓
5. Buat Provider
       ↓
6. Buat Page
       ↓
7. Buat Widget
```

Contoh:

```text
Job Feature

job_model.dart
       ↓
job_service.dart
       ↓
job_repository.dart
       ↓
job_provider.dart
       ↓
job_page.dart
       ↓
job_card.dart
```

---

# Project Architecture Summary

```text
                    Flutter Application
                            │
                            ▼
                     Presentation Layer
                  Pages / Widgets / Providers
                            │
                            ▼
                       Repository Layer
                            │
                            ▼
                        Service Layer
                            │
                            ▼
                          Dio Client
                            │
                            ▼
                     Laravel REST API
                            │
                            ▼
                          Database
```

---

# SIKARIR

> **Menghubungkan Pelatihan, Kompetensi, dan Kesempatan Kerja.**

SIKARIR merupakan platform digital yang mengintegrasikan peserta, BLK, Disnaker, dan perusahaan untuk menciptakan proses pelatihan dan pengembangan karier yang terintegrasi.

```text
Pelatihan
    ↓
Kompetensi
    ↓
Sertifikasi
    ↓
Skill Matching
    ↓
Kesempatan Kerja
```
