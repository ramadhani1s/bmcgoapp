# BMC Admin Portal

Aplikasi web admin untuk sistem BMC (Bimbingan Belajar) yang memungkinkan login sebagai Admin atau Mentor dengan role-based authentication.

## Fitur

- **Role-based Authentication**: Sistem login yang membedakan Admin dan Mentor
- **Admin Dashboard**: Dashboard lengkap untuk mengelola sistem
- **Mentor Dashboard**: Dashboard khusus untuk mentor mengelola kelas dan siswa
- **Responsive Design**: UI yang responsive dan modern
- **Secure Login**: Sistem autentikasi yang aman dengan JWT token

## Struktur Role

- **Admin (Role ID: 1)**: Akses penuh ke semua fitur sistem
- **Mentor (Role ID: 2)**: Akses terbatas untuk mengelola kelas dan siswa
- **Siswa (Role ID: 3)**: Tidak didukung di aplikasi website ini (gunakan mobile app)

## Cara Menjalankan

1. **Setup Backend**
   ```bash
   cd ../backend
   go run main.go
   ```

2. **Setup Frontend Website**
   ```bash
   cd frontend_website_bmc
   flutter pub get
   flutter run -d web-server --web-port=3000
   ```

3. **Akses Aplikasi**
   - Buka browser dan akses: `http://localhost:3000`

## Akun Test

### Admin Account
- Email: admin@bmc.com
- Password: admin123

### Mentor Account
- Email: mentor@bmc.com
- Password: mentor123

## API Endpoints

Aplikasi ini terhubung ke backend Go dengan endpoints berikut:

- `POST /auth/login` - Login user
- `GET /api/profile` - Get user profile
- `GET /api/admin/dashboard` - Admin dashboard (role 1 only)
- `GET /api/mentor/kelas` - Mentor classes (role 2 only)

## Teknologi

- **Frontend**: Flutter Web
- **Backend**: Go with Gin framework
- **Database**: MySQL/PostgreSQL
- **Authentication**: JWT Token
- **State Management**: Shared Preferences

## Struktur Folder

```
lib/
├── models/
│   └── user.dart              # Model User
├── services/
│   └── auth_service.dart      # Service autentikasi
├── screens/
│   ├── auth/
│   │   └── login_screen.dart  # Halaman login
│   └── dashboard/
│       ├── admin_dashboard.dart    # Dashboard admin
│       └── mentor_dashboard.dart   # Dashboard mentor
├── routes/
│   └── app_routes.dart        # Konfigurasi routing
└── main.dart                  # Entry point aplikasi
```

## Development

Untuk menambah fitur baru:

1. Tambahkan model di `lib/models/`
2. Buat service di `lib/services/`
3. Buat screen di `lib/screens/`
4. Update routing di `lib/routes/app_routes.dart`
5. Pastikan backend API sudah tersedia

## Catatan

- Pastikan backend server berjalan di `http://localhost:8080`
- Aplikasi ini khusus untuk Admin dan Mentor
- Siswa harus menggunakan aplikasi mobile
