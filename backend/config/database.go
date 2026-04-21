package config

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

var DB *pgxpool.Pool

func ConnectDB() {
	dsn := buildDSN()

	var err error
	// 1. Membuat konfigurasi pool
	DB, err = pgxpool.New(context.Background(), dsn)
	if err != nil {
		log.Fatal("Format DSN salah atau gagal buat pool:", err)
	}

	// 2. TES KONEKSI ASLI (Sangat Penting!)
	err = DB.Ping(context.Background())
	if err != nil {
		if strings.Contains(err.Error(), `database "`) && strings.Contains(err.Error(), `does not exist`) {
			log.Fatalf("Database belum ada. Buat dulu DB '%s'. Detail: %v", getEnv("DB_NAME", "bmcgo_db"), err)
		}
		log.Fatal("Gagal konek ke database (Cek apakah DB sudah nyala/password benar):", err)
	}

	log.Println("✅ Real connection established to database")
}

func buildDSN() string {
	if databaseURL := os.Getenv("DATABASE_URL"); databaseURL != "" {
		return databaseURL
	}

	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "")
	name := getEnv("DB_NAME", "bmcgo_db")
	sslMode := getEnv("DB_SSLMODE", "disable")

	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", user, password, host, port, name, sslMode)
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
