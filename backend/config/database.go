package config

import (
	"context"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

var DB *pgxpool.Pool

func ConnectDB() {
	dsn := "postgres://postgres:yohana@localhost:5432/bimbel_bmc"

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
}
