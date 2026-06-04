package config

import (
	"context"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
)

var DB *pgxpool.Pool

func ConnectDB() {
	// WAJIB baca dari environment variable
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL is not set. Please add it in Railway Variables.")
	}

	log.Println("Connecting to database with DATABASE_URL")

	var err error
	DB, err = pgxpool.New(context.Background(), dsn)
	if err != nil {
		log.Fatal("Failed to create connection pool:", err)
	}

	err = DB.Ping(context.Background())
	if err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	log.Println("✅ Database connected successfully!")
}
