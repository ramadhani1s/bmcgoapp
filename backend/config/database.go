package config

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
)

var DB *pgxpool.Pool

func ConnectDB() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = "postgres://postgres:yohana@localhost:5432/bmcgo_db?sslmode=disable"
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
}
