package config

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
)

var DB *pgxpool.Pool

func ConnectDB() {
	// Coba baca dari environment variable
	dsn := os.Getenv("DATABASE_URL")

	// Fallback untuk local development
	if dsn == "" {
		// Deteksi apakah ini environment Railway
		if os.Getenv("RAILWAY_ENVIRONMENT") == "" {
			// Ini LOCAL, pake database lokal
			dsn = "postgres://postgres:ramadhani12@localhost:5432/bmcgo_app?sslmode=disable"
			log.Println("⚠️ Using LOCAL database (localhost:5432)")
		} else {
			log.Fatal("DATABASE_URL environment variable is not set in Railway")
		}
	}

	// Buat koneksi pool
	var err error
	DB, err = pgxpool.New(context.Background(), dsn)
	if err != nil {
		log.Fatal("Format DSN salah atau gagal buat pool:", err)
	}

	// Test koneksi
	err = DB.Ping(context.Background())
	if err != nil {
		log.Fatal("Gagal konek ke database:", err)
	}

	log.Println("✅ Real connection established to database")

	// ================================================
	// HAPUS SEMUA CREATE TABLE! Database sudah siap dari bmcgo.sql
	// Cukup tambahin index dan kolom yang mungkin kurang aja
	// ================================================

	// Sinkronisasi minimal untuk users (hanya kolom yang mungkin kurang)
	_, err = DB.Exec(context.Background(), `
		ALTER TABLE IF EXISTS users
		ADD COLUMN IF NOT EXISTS nama VARCHAR(255),
		ADD COLUMN IF NOT EXISTS username VARCHAR(255),
		ADD COLUMN IF NOT EXISTS email VARCHAR(255),
		ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20),
		ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'pending',
		ADD COLUMN IF NOT EXISTS fcm_token TEXT
	`)
	if err != nil {
		log.Println("⚠️ Warning: gagal sinkronisasi kolom users:", err)
	}

	// Backfill nama dari username jika perlu
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
		log.Println("⚠️ Warning: gagal backfill nama dari username:", err)
	}

	// Unique index untuk email users
	_, err = DB.Exec(context.Background(), `
		CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique
		ON users (email)
		WHERE email IS NOT NULL
	`)
	if err != nil {
		log.Println("⚠️ Warning: gagal membuat unique index email users:", err)
	}

	// Index untuk paket_les
	_, err = DB.Exec(context.Background(), `
		CREATE INDEX IF NOT EXISTS idx_paket_les_status
		ON paket_les (status)
	`)
	if err != nil {
		log.Println("⚠️ Warning: gagal membuat index status paket_les:", err)
	}

	log.Println("✅ Database initialization completed")
}
