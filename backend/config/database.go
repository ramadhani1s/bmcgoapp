package config

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
)

var DB *pgxpool.Pool

func ConnectDB() {
	dsn := os.Getenv("BMC_DB_DSN")
	if dsn == "" {
		// Default lokal: pakai database bmcgo_db dan matikan TLS.
		// Jika DB kamu beda, set BMC_DB_DSN ke connection string yang benar.
		dsn = "postgres://postgres@localhost:5432/bmcgo_db?sslmode=disable"
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
