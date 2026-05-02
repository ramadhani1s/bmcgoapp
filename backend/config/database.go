package config

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
)

var DB *pgxpool.Pool

func ConnectDB() {
	// Allow overriding via environment variable DATABASE_URL
	// Default includes sslmode=disable for local development where Postgres may not accept TLS
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		// Use the project's default local database name if no DATABASE_URL provided
		dsn = "postgres://postgres:ramadhani12@localhost:5432/bmcgo_db?sslmode=disable"
	}

	var err error
	// 1. Membuat konfigurasi pool
	DB, err = pgxpool.New(context.Background(), dsn)
	if err != nil {
		log.Fatal("Format DSN salah atau gagal buat pool:", err)
	}

	// 2. TES KONEKSI ASLI (Sangat Penting!)
	err = DB.Ping(context.Background())
	if err != nil {
		log.Fatal("Gagal konek ke database (Cek apakah DB sudah nyala/password benar):", err)
	}

	log.Println("✅ Real connection established to database")

	// Sinkronisasi schema minimum agar query auth/register tidak gagal
	_, err = DB.Exec(context.Background(), `
		ALTER TABLE IF EXISTS users
		ADD COLUMN IF NOT EXISTS nama VARCHAR(255),
		ADD COLUMN IF NOT EXISTS username VARCHAR(255),
		ADD COLUMN IF NOT EXISTS email VARCHAR(255),
		ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20)
	`)
	if err != nil {
		log.Fatal("Gagal sinkronisasi kolom users:", err)
	}

	_, err = DB.Exec(context.Background(), `
		DO $$
		BEGIN
			IF EXISTS (
				SELECT 1 FROM information_schema.columns
				WHERE table_name = 'users' AND column_name = 'username'
			) THEN
				EXECUTE 'UPDATE users
					SET nama = COALESCE(NULLIF(nama, ''''), username)
					WHERE (nama IS NULL OR nama = '''')';
			END IF;
		END
		$$
	`)
	if err != nil {
		log.Println("Warning: gagal backfill nama dari username:", err)
	}

	// Backfill data login mentor lama jika email/password masih disimpan di tabel mentor.
	_, err = DB.Exec(context.Background(), `
		DO $$
		BEGIN
			IF EXISTS (
				SELECT 1 FROM information_schema.columns
				WHERE table_name = 'mentor' AND column_name = 'email'
			) THEN
				EXECUTE '
					UPDATE users u
					SET
						email = COALESCE(NULLIF(u.email, ''''), m.email),
						username = COALESCE(NULLIF(u.username, ''''), m.email)
					FROM mentor m
					WHERE m.user_id = u.id
						AND m.email IS NOT NULL AND m.email <> ''''
				';
			END IF;

			IF EXISTS (
				SELECT 1 FROM information_schema.columns
				WHERE table_name = 'mentor' AND column_name = 'password'
			) THEN
				EXECUTE '
					UPDATE users u
					SET password = COALESCE(NULLIF(u.password, ''''), m.password)
					FROM mentor m
					WHERE m.user_id = u.id
						AND m.password IS NOT NULL AND m.password <> ''''
				';
			END IF;
		END
		$$
	`)
	if err != nil {
		log.Println("Warning: gagal backfill users dari mentor:", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique
		ON users (email)
		WHERE email IS NOT NULL
	`)
	if err != nil {
		log.Println("Warning: gagal membuat unique index email users:", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS payment_transactions (
			transaction_id VARCHAR(255) PRIMARY KEY,
			user_id INT NOT NULL,
			package_id VARCHAR(255),
			package_title VARCHAR(255),
			amount BIGINT,
			status VARCHAR(50),
			payment_type VARCHAR(100),
			customer_name VARCHAR(255),
			customer_email VARCHAR(255),
			customer_phone VARCHAR(100),
			is_verified BOOLEAN DEFAULT FALSE,
			verified_at TIMESTAMP,
			verified_by_admin INT,
			created_at TIMESTAMP NOT NULL DEFAULT NOW(),
			updated_at TIMESTAMP NOT NULL DEFAULT NOW()
		)
	`)
	if err != nil {
		log.Fatal("Gagal membuat table payment_transactions:", err)
	}

	// Add columns if they don't exist (for existing databases)
	_, err = DB.Exec(context.Background(), `
		ALTER TABLE payment_transactions
		ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE,
		ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP,
		ADD COLUMN IF NOT EXISTS verified_by_admin INT
	`)
	if err != nil {
		log.Println("Warning: Could not add verification columns (might already exist):", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS attendance_sessions (
			id SERIAL PRIMARY KEY,
			mentor_id INT NOT NULL,
			class_name VARCHAR(120) NOT NULL,
			subject VARCHAR(120),
			token VARCHAR(20) NOT NULL,
			started_at TIMESTAMP NOT NULL DEFAULT NOW(),
			hadir_deadline TIMESTAMP NOT NULL,
			terlambat_deadline TIMESTAMP NOT NULL,
			status VARCHAR(30) NOT NULL DEFAULT 'aktif'
		)
	`)
	if err != nil {
		log.Fatal("Gagal membuat table attendance_sessions:", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS attendance_records (
			id SERIAL PRIMARY KEY,
			session_id INT NOT NULL,
			siswa_id INT NOT NULL,
			status VARCHAR(30) NOT NULL,
			submitted_at TIMESTAMP NOT NULL DEFAULT NOW(),
			UNIQUE(session_id, siswa_id)
		)
	`)
	if err != nil {
		log.Fatal("Gagal membuat table attendance_records:", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE INDEX IF NOT EXISTS idx_attendance_sessions_token
		ON attendance_sessions (token)
	`)
	if err != nil {
		log.Println("Warning: gagal membuat index token attendance_sessions:", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE INDEX IF NOT EXISTS idx_attendance_records_siswa
		ON attendance_records (siswa_id)
	`)
	if err != nil {
		log.Println("Warning: gagal membuat index siswa attendance_records:", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS tryout (
			id SERIAL PRIMARY KEY,
			paket_id INT NOT NULL,
			mentor_id INT NOT NULL,
			class_level VARCHAR(50) DEFAULT 'Kelas 12',
			judul TEXT,
			tanggal TIMESTAMP,
			durasi INT DEFAULT 0,
			total_questions INT DEFAULT 0,
			category_questions JSONB DEFAULT '{}'::jsonb
		)
	`)
	if err != nil {
		log.Fatal("Gagal membuat table tryout:", err)
	}

	_, err = DB.Exec(context.Background(), `
		ALTER TABLE IF EXISTS tryout
		ADD COLUMN IF NOT EXISTS class_level VARCHAR(50) DEFAULT 'Kelas 12',
		ADD COLUMN IF NOT EXISTS judul TEXT,
		ADD COLUMN IF NOT EXISTS tanggal TIMESTAMP,
		ADD COLUMN IF NOT EXISTS durasi INT DEFAULT 0,
		ADD COLUMN IF NOT EXISTS total_questions INT DEFAULT 0,
		ADD COLUMN IF NOT EXISTS category_questions JSONB DEFAULT '{}'::jsonb
	`)
	if err != nil {
		log.Println("Warning: gagal sinkronisasi kolom tryout:", err)
	}

	// Buat table mentor
	_, err = DB.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS mentor (
			id SERIAL PRIMARY KEY,
			user_id INT,
			nama_mentor VARCHAR(255) NOT NULL,
			email VARCHAR(255),
			password VARCHAR(500),
			mata_pelajaran VARCHAR(255),
			status VARCHAR(50) DEFAULT 'Aktif',
			bio TEXT,
			created_at TIMESTAMP DEFAULT NOW(),
			updated_at TIMESTAMP DEFAULT NOW()
		)
	`)
	if err != nil {
		log.Fatal("Gagal membuat table mentor:", err)
	}

	// Add missing columns to mentor table for existing databases
	_, err = DB.Exec(context.Background(), `
		ALTER TABLE IF EXISTS mentor
		ADD COLUMN IF NOT EXISTS email VARCHAR(255),
		ADD COLUMN IF NOT EXISTS password VARCHAR(500),
		ADD COLUMN IF NOT EXISTS user_id INT,
		ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'Aktif'
	`)
	if err != nil {
		log.Println("Warning: gagal sinkronisasi kolom mentor:", err)
	}

	// Pastikan user_id nullable (tidak ada NOT NULL constraint)
	_, err = DB.Exec(context.Background(), `
		ALTER TABLE IF EXISTS mentor
		ALTER COLUMN user_id DROP NOT NULL
	`)
	if err != nil {
		log.Println("Warning: gagal alter user_id to nullable:", err)
	}

	// Rename spesialisasi to mata_pelajaran jika belum
	_, err = DB.Exec(context.Background(), `
		DO $$
		BEGIN
			IF EXISTS (
				SELECT 1 FROM information_schema.columns
				WHERE table_name = 'mentor' AND column_name = 'spesialisasi'
			) THEN
				IF NOT EXISTS (
					SELECT 1 FROM information_schema.columns
					WHERE table_name = 'mentor' AND column_name = 'mata_pelajaran'
				) THEN
					EXECUTE 'ALTER TABLE mentor RENAME COLUMN spesialisasi TO mata_pelajaran';
				END IF;
			END IF;
		END
		$$
	`)
	if err != nil {
		log.Println("Warning: gagal rename spesialisasi to mata_pelajaran:", err)
	}

	// Add mata_pelajaran if it doesn't exist
	_, err = DB.Exec(context.Background(), `
		ALTER TABLE IF EXISTS mentor
		ADD COLUMN IF NOT EXISTS mata_pelajaran VARCHAR(255)
	`)
	if err != nil {
		log.Println("Warning: gagal add mata_pelajaran:", err)
	}

	// Buat table materi_pembelajaran (learning_materials)
	_, err = DB.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS learning_materials (
			id SERIAL PRIMARY KEY,
			mentor_id INT NOT NULL,
			title VARCHAR(255) NOT NULL,
			description TEXT,
			file_path VARCHAR(500) NOT NULL,
			file_type VARCHAR(50),
			file_size BIGINT,
			created_at TIMESTAMP NOT NULL DEFAULT NOW(),
			updated_at TIMESTAMP NOT NULL DEFAULT NOW()
		)
	`)
	if err != nil {
		log.Fatal("Gagal membuat table learning_materials:", err)
	}

	// Buat table paket_les (lesson packages)
	_, err = DB.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS paket_les (
			id SERIAL PRIMARY KEY,
			nama_paket VARCHAR(100) NOT NULL,
			harga_awal BIGINT NOT NULL,
			diskon INT DEFAULT 0,
			tanggal_mulai_promo DATE,
			tanggal_selesai_promo DATE,
			deskripsi TEXT,
			durasi INT,
			status VARCHAR(50) DEFAULT 'aktif',
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		log.Fatal("Gagal membuat table paket_les:", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE INDEX IF NOT EXISTS idx_paket_les_status
		ON paket_les (status)
	`)
	if err != nil {
		log.Println("Warning: gagal membuat index status paket_les:", err)
	}

	// Drop jadwal_pembelajaran jika ada (migration)
	_, err = DB.Exec(context.Background(), `
		DROP TABLE IF EXISTS jadwal_pembelajaran CASCADE
	`)
	if err != nil {
		log.Println("Warning: gagal drop jadwal_pembelajaran:", err)
	}

	// Buat table jadwal (learning schedule) dengan relational schema
	_, err = DB.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS jadwal (
			id SERIAL PRIMARY KEY,
			paket_id INTEGER NOT NULL,
			mentor_id INTEGER NOT NULL,
			mata_pelajaran VARCHAR(100),
			hari VARCHAR(20),
			jam_mulai TIME,
			jam_selesai TIME,
			ruang VARCHAR(50),
			FOREIGN KEY (paket_id) REFERENCES paket_les(id) ON DELETE CASCADE,
			FOREIGN KEY (mentor_id) REFERENCES mentor(id) ON DELETE CASCADE
		)
	`)
	if err != nil {
		log.Fatal("Gagal membuat table jadwal:", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE INDEX IF NOT EXISTS idx_jadwal_paket_id
		ON jadwal (paket_id)
	`)
	if err != nil {
		log.Println("Warning: gagal membuat index paket_id jadwal:", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE INDEX IF NOT EXISTS idx_jadwal_mentor_id
		ON jadwal (mentor_id)
	`)
	if err != nil {
		log.Println("Warning: gagal membuat index mentor_id jadwal:", err)
	}

	_, err = DB.Exec(context.Background(), `
		CREATE INDEX IF NOT EXISTS idx_jadwal_hari
		ON jadwal (hari)
	`)
	if err != nil {
		log.Println("Warning: gagal membuat index hari jadwal:", err)
	}

	// Buat table pengumuman (announcements)
	_, err = DB.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS pengumuman (
			id SERIAL PRIMARY KEY,
			admin_id INTEGER NOT NULL,
			judul VARCHAR(255) NOT NULL,
			isi TEXT NOT NULL,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (admin_id) REFERENCES admin(id)
		)
	`)
	if err != nil {
		log.Fatal("Gagal membuat table pengumuman:", err)
	}

	// Buat table soal_latihan untuk menyimpan soal latihan mentor
	_, err = DB.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS soal_latihan (
			id SERIAL PRIMARY KEY,
			mentor_id INT NOT NULL,
			pertanyaan TEXT NOT NULL,
			pilihan_a TEXT NOT NULL,
			pilihan_b TEXT NOT NULL,
			pilihan_c TEXT NOT NULL,
			pilihan_d TEXT NOT NULL,
			jawaban VARCHAR(1) NOT NULL,
			pembahasan TEXT,
			created_at TIMESTAMP DEFAULT NOW(),
			updated_at TIMESTAMP DEFAULT NOW(),
			FOREIGN KEY (mentor_id) REFERENCES mentor(id) ON DELETE CASCADE
		)
	`)
	if err != nil {
		log.Fatal("Gagal membuat table soal_latihan:", err)
	}

	// Pastikan kolom pembahasan ada (untuk database lama yang tidak memiliki kolom ini)
	_, err = DB.Exec(context.Background(), `
		DO $$
		BEGIN
			IF NOT EXISTS (
				SELECT 1 FROM information_schema.columns
				WHERE table_name = 'soal_latihan' AND column_name = 'pembahasan'
			) THEN
				ALTER TABLE soal_latihan ADD COLUMN pembahasan TEXT;
			END IF;
		END
		$$
	`)
	if err != nil {
		log.Println("Warning: gagal add kolom pembahasan di soal_latihan:", err)
	}

	// Sinkronkan admin.user_id berdasarkan email agar FK pengumuman selalu menunjuk admin yang benar.
	_, err = DB.Exec(context.Background(), `
		DO $$
		BEGIN
			IF EXISTS (
				SELECT 1 FROM information_schema.tables WHERE table_name = 'admin'
			) AND EXISTS (
				SELECT 1 FROM information_schema.tables WHERE table_name = 'users'
			) THEN
				EXECUTE '
					UPDATE admin a
					SET user_id = u.id
					FROM users u
					WHERE lower(trim(a.email)) = lower(trim(u.email))
						AND (a.user_id IS DISTINCT FROM u.id)
				';
			END IF;
		END
		$$
	`)
	if err != nil {
		log.Println("Warning: gagal sinkronisasi admin.user_id:", err)
	}

}
