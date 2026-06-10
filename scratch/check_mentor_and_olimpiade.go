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

	// Check mentors
	fmt.Println("--- MENTOR TABLE ---")
	rows, err := conn.Query(ctx, "SELECT id, user_id, nama, spesialisasi FROM mentor")
	if err != nil {
		log.Fatalf("Gagal query mentor: %v", err)
	}
	defer rows.Close()
	for rows.Next() {
		var id, userID int
		var nama, spesialisasi string
		if err := rows.Scan(&id, &userID, &nama, &spesialisasi); err != nil {
			log.Printf("Scan error: %v", err)
			continue
		}
		fmt.Printf("Mentor ID: %d, UserID: %d, Nama: %s, Spesialisasi: %s\n", id, userID, nama, spesialisasi)
	}

	// Check users of role mentor
	fmt.Println("\n--- USERS (ROLE=2) ---")
	rows2, err := conn.Query(ctx, "SELECT id, username, nama, role_id FROM users WHERE role_id = 2")
	if err != nil {
		log.Fatalf("Gagal query users: %v", err)
	}
	defer rows2.Close()
	for rows2.Next() {
		var id, roleID int
		var username, nama string
		if err := rows2.Scan(&id, &username, &nama, &roleID); err != nil {
			log.Printf("Scan error: %v", err)
			continue
		}
		fmt.Printf("User ID: %d, Username: %s, Nama: %s, RoleID: %d\n", id, username, nama, roleID)
	}

	// Check olimpiade rows
	fmt.Println("\n--- OLIMPIADE ROWS ---")
	rows3, err := conn.Query(ctx, "SELECT id, mentor_id, class_level, nama, tanggal FROM olimpiade")
	if err != nil {
		log.Fatalf("Gagal query olimpiade: %v", err)
	}
	defer rows3.Close()
	for rows3.Next() {
		var id, mentorID int
		var classLevel, nama string
		var tanggal interface{}
		if err := rows3.Scan(&id, &mentorID, &classLevel, &nama, &tanggal); err != nil {
			log.Printf("Scan error: %v", err)
			continue
		}
		fmt.Printf("Olimpiade ID: %d, MentorID: %d, ClassLevel: %s, Nama: %s, Tanggal: %v\n", id, mentorID, classLevel, nama, tanggal)
	}
}
