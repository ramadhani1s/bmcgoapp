//go:build ignore

// Run this script once to apply DB migrations:
//   go run migrate.go
package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5"
)

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		// Try to read from the local config file pattern used by the backend
		dsn = "host=localhost user=postgres password=postgres dbname=bmcgoapp sslmode=disable"
		fmt.Println("DATABASE_URL not set, using default:", dsn)
	}

	conn, err := pgx.Connect(context.Background(), dsn)
	if err != nil {
		log.Fatalf("Gagal koneksi DB: %v", err)
	}
	defer conn.Close(context.Background())

	// 1. Buat tabel hasil_latihan jika belum ada
	_, err = conn.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS hasil_latihan (
		    id         SERIAL PRIMARY KEY,
		    siswa_id   INTEGER NOT NULL,
		    materi_id  INTEGER NOT NULL,
		    latihan_title VARCHAR(255) NOT NULL DEFAULT 'Latihan Soal',
		    skor       INTEGER NOT NULL DEFAULT 0,
		    total_soal INTEGER NOT NULL DEFAULT 0,
		    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		    UNIQUE (siswa_id, materi_id, latihan_title)
		)
	`)
	if err != nil {
		log.Fatalf("Gagal membuat tabel hasil_latihan: %v", err)
	}
	fmt.Println("✅ Tabel hasil_latihan OK")

	// 2. Tambah index
	_, err = conn.Exec(context.Background(), `
		CREATE INDEX IF NOT EXISTS idx_hasil_latihan_siswa ON hasil_latihan(siswa_id)
	`)
	if err != nil {
		log.Printf("Warning: gagal membuat index: %v", err)
	} else {
		fmt.Println("✅ Index idx_hasil_latihan_siswa OK")
	}

	// 3. Tambah kolom durasi ke olimpiade jika belum ada
	_, err = conn.Exec(context.Background(), `
		DO $$ BEGIN
		    IF NOT EXISTS (
		        SELECT 1 FROM information_schema.columns
		        WHERE table_name = 'olimpiade' AND column_name = 'durasi'
		    ) THEN
		        ALTER TABLE olimpiade ADD COLUMN durasi INTEGER NOT NULL DEFAULT 120;
		    END IF;
		END $$
	`)
	if err != nil {
		log.Fatalf("Gagal menambah kolom durasi: %v", err)
	}
	fmt.Println("✅ Kolom durasi di tabel olimpiade OK")

	fmt.Println("\n🎉 Migration selesai!")
}
