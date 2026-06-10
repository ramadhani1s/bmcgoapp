package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5"
)

func main() {
	dsn := "postgresql://postgres:yohana@localhost:5432/bmcgo_db"
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dsn)
	if err != nil {
		log.Fatalf("Gagal konek: %v", err)
	}
	defer conn.Close(ctx)

	// Check announcements (pengumuman)
	fmt.Println("--- PENGUMUMAN ---")
	var count int
	err = conn.QueryRow(ctx, "SELECT COUNT(*) FROM pengumuman").Scan(&count)
	if err != nil {
		log.Printf("Gagal hitung pengumuman: %v", err)
	} else {
		fmt.Printf("Total pengumuman: %d\n", count)
	}

	rows, err := conn.Query(ctx, "SELECT id, judul, isi, created_at FROM pengumuman LIMIT 5")
	if err != nil {
		log.Printf("Gagal query pengumuman: %v", err)
	} else {
		defer rows.Close()
		for rows.Next() {
			var id int
			var judul, isi string
			var createdAt interface{}
			if err := rows.Scan(&id, &judul, &isi, &createdAt); err != nil {
				log.Printf("Error scan: %v", err)
				continue
			}
			fmt.Printf("ID: %d, Judul: %s, Isi: %s, CreatedAt: %v\n", id, judul, isi, createdAt)
		}
	}

	// Check olimpiade
	fmt.Println("\n--- OLIMPIADE ---")
	err = conn.QueryRow(ctx, "SELECT COUNT(*) FROM olimpiade").Scan(&count)
	if err != nil {
		log.Printf("Gagal hitung olimpiade: %v", err)
	} else {
		fmt.Printf("Total olimpiade: %d\n", count)
	}

	rows2, err := conn.Query(ctx, "SELECT id, judul, tanggal, durasi FROM olimpiade LIMIT 5")
	if err != nil {
		log.Printf("Gagal query olimpiade: %v", err)
	} else {
		defer rows2.Close()
		for rows2.Next() {
			var id int
			var judul string
			var tanggal interface{}
			var durasi interface{}
			if err := rows2.Scan(&id, &judul, &tanggal, &durasi); err != nil {
				log.Printf("Error scan: %v", err)
				continue
			}
			fmt.Printf("ID: %d, Judul: %s, Tanggal: %v, Durasi: %v\n", id, judul, tanggal, durasi)
		}
	}
}
