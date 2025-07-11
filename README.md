# 🍳 MyRecipes - Personal Recipe Manager

**Aplikasi Mobile untuk Manajemen Resep Pribadi**

📚 **UAS AMBW - C14220176 / Benedict Janvier Setiawan**

Aplikasi Flutter modern yang memungkinkan pengguna untuk menyimpan, mengelola, dan berbagi resep masakan favorit mereka dengan integrasi cloud database menggunakan Supabase.

## ✨ Fitur Utama

- 🔐 **Autentikasi Pengguna**: Sign up, sign in, dan sign out dengan Supabase Auth
- ☁️ **Database Cloud**: Penyimpanan resep di Supabase dengan Row Level Security
- 💾 **Session Persistence**: Auto-login menggunakan SharedPreferences
- 🚀 **Get Started Screen**: Layar welcome sekali tampil untuk pengguna baru
- 📝 **Manajemen Resep**: Tambah, lihat, hapus, dan cari resep pribadi dengan bahan dan langkah memasak
- 🔒 **Keamanan Data**: Setiap pengguna hanya dapat mengakses resep miliknya sendiri
- 🎨 **UI Modern**: Desain yang elegan dengan tema orange & cream
- 📱 **Navigation Bar**: Bottom navigation yang intuitif untuk navigasi antar halaman
- 👤 **Profile Management**: Edit profil pengguna dengan foto dan informasi pribadi

## 🎯 Teknologi yang Digunakan

### Frontend

- **Flutter** - UI framework untuk pengembangan aplikasi mobile cross-platform
- **Dart** - Bahasa pemrograman untuk Flutter

### Backend & Database

- **Supabase** - Backend-as-a-Service untuk autentikasi dan database PostgreSQL

### State Management & Navigation

- **Riverpod** - State management yang modern dan type-safe
- **GoRouter** - Routing dan navigasi deklaratif
- **Flutter Hooks** - Manajemen state UI yang efisien

### Local Storage

- **SharedPreferences** - Penyimpanan lokal untuk session persistence

### UI/UX Libraries

- **Google Fonts** - Font kustom untuk desain yang menarik
- **Cached Network Image** - Optimasi loading gambar
- **Image Picker** - Pengambilan gambar dari galeri/kamera

## 🛠️ Instalasi dan Build

### Prerequisites

Pastikan Anda telah menginstall:

- Flutter SDK (versi 3.8.1 atau lebih baru)
- Dart SDK
- Android Studio atau VS Code dengan Flutter extension
- Emulator Android atau perangkat fisik untuk testing

### Langkah Instalasi

1. **Install Dependencies**

   ```bash
   flutter pub get
   ```

2. **Setup Supabase** (Opsional - untuk development)

   - Buat project baru di [Supabase](https://supabase.com)
   - Copy URL dan anon key ke `lib/config/supabase_config.dart`
   - Run SQL scripts yang ada di root folder untuk setup database

3. **Run Aplikasi**

   ```bash
   # Debug mode
   flutter run

   # Release mode
   flutter run --release
   ```

## 🧪 Testing Credentials

Untuk keperluan testing, Anda dapat:

1. **Membuat akun baru** melalui halaman Sign Up
2. **Menggunakan kredensial test** (jika tersedia):
   - Email: test@example.com
   - Password: test123456

## 📁 Struktur Proyek

```
lib/
├── config/
│   ├── app_theme.dart       # Konfigurasi tema aplikasi
│   ├── router.dart          # Konfigurasi routing
│   └── supabase_config.dart # Konfigurasi Supabase
├── models/
│   ├── ingredient.dart      # Model data bahan masakan
│   ├── recipe.dart          # Model data resep
│   └── user_profile.dart    # Model data profil pengguna
├── providers/
│   └── app_providers.dart   # Riverpod providers
├── screens/
│   ├── add_recipe_screen.dart      # Halaman tambah resep
│   ├── edit_profile_screen.dart    # Halaman edit profil
│   ├── get_started_screen.dart     # Halaman welcome
│   ├── home_screen.dart            # Halaman utama
│   ├── profile_screen.dart         # Halaman profil
│   ├── recipe_detail_screen.dart   # Halaman detail resep
│   ├── scaffold_with_nav_bar.dart  # Layout dengan bottom nav
│   ├── sign_in_screen.dart         # Halaman login
│   ├── sign_up_screen.dart         # Halaman registrasi
│   └── splash_screen.dart          # Halaman splash
├── services/
│   ├── auth_service.dart           # Service autentikasi
│   ├── recipe_service.dart         # Service manajemen resep
│   └── shared_prefs_service.dart   # Service local storage
├── utils/
│   └── helpers.dart                # Utility functions
├── widgets/
│   └── recipe_card.dart            # Widget kartu resep
└── main.dart                       # Entry point aplikasi
```
