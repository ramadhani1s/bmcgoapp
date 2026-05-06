package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5"
)

func testQuery() {
	connStr := "host=localhost user=root password=root dbname=bmc sslmode=disable"
	conn, err := pgx.Connect(context.Background(), connStr)
	if err != nil {
		log.Printf("❌ Failed to connect: %v", err)
		return
	}
	defer conn.Close(context.Background())

	var count int
	err = conn.QueryRow(context.Background(), "SELECT COUNT(*) FROM payment_transactions WHERE status = $1 AND is_verified = $2", "success", false).Scan(&count)
	if err != nil {
		log.Printf("❌ Query failed: %v", err)
		return
	}

	fmt.Printf("✅ Pending verifications in DB: %d\n", count)

	// Get actual records
	rows, err := conn.Query(context.Background(), `
		SELECT DISTINCT ON (pt.user_id)
			pt.transaction_id,
			pt.user_id,
			COALESCE(pt.customer_name, NULLIF(u.nama, ''), '') AS student_name,
			pt.status,
			pt.is_verified,
			pt.created_at
		FROM payment_transactions pt
		LEFT JOIN users u ON u.id = pt.user_id
		WHERE pt.status = 'success' AND COALESCE(pt.is_verified, FALSE) = FALSE
		ORDER BY pt.user_id, pt.created_at DESC
		LIMIT 5
	`)
	if err != nil {
		log.Printf("❌ Query records failed: %v", err)
		return
	}
	defer rows.Close()

	fmt.Println("Records:")
	for rows.Next() {
		var transID string
		var userID int
		var studentName string
		var status string
		var isVerified bool
		var createdAt interface{}

		err := rows.Scan(&transID, &userID, &studentName, &status, &isVerified, &createdAt)
		if err != nil {
			log.Printf("❌ Scan error: %v", err)
			continue
		}

		fmt.Printf("  TransID: %s, UserID: %d, Name: %s, Status: %s, Verified: %v, Created: %v\n",
			transID, userID, studentName, status, isVerified, createdAt)
	}
}
