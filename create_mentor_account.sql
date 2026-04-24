-- ===================================================
-- CREATE MENTOR ACCOUNT: Dr. Muhammad Rizki
-- ===================================================

-- Password hash untuk "mentor123" (menggunakan bcrypt)
-- Hash ini bisa di-generate ulang atau pakai password yang berbeda
-- Untuk testing sekarang pakai password: mentor123

-- 1. Insert ke tabel users (role_id = 2 adalah Mentor)
INSERT INTO users (role_id, username, password, status)
VALUES (
  2,
  'muhammadrizki@bmc.local',
  '$2a$10$gSvqqUNWHCHvF1mAreHQWODlH97IW5NeVeDD5K9vbEJGWQYcIKKwm',  -- bcrypt hash dari "mentor123"
  'aktif'
)
RETURNING id;

-- Catatan: Ganti value ID berikut dengan ID yang di-return dari query di atas
-- Misal jika return ID=100, gunakan 100 di query berikutnya

-- 2. Insert ke tabel mentor dengan user_id dari step 1
-- Sesuaikan user_id dengan hasil dari query di atas
INSERT INTO mentor (user_id, nama_mentor, spesialisasi, bio)
VALUES (
  999998,  -- GANTI INI dengan ID dari query step 1
  'Dr. Muhammad Rizki',
  'Matematika',
  'Mentor berpengalaman dalam mengajar Matematika untuk tingkat SMA'
);

-- Setelah insert, coba login ke website dengan:
-- Email: muhammadrizki@bmc.local
-- Password: mentor123
