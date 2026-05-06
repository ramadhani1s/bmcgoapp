package main

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5"
)

func main() {
	if len(os.Args) < 2 || os.Args[1] != "test-query" {
		fmt.Println("Run with: go run . test-query")
		os.Exit(1)
	}

	connStr := "host=localhost user=root password=root dbname=bmc sslmode=disable"
	conn, err := pgx.Connect(context.Background(), connStr)
	if err != nil {
		fmt.Printf("❌ Failed to connect: %v\n", err)
		return
	}
	defer conn.Close(context.Background())

	var count int
	err = conn.QueryRow(context.Background(), "SELECT COUNT(*) FROM payment_transactions WHERE status = $1 AND is_verified = $2", "success", false).Scan(&count)
	if err != nil {
		fmt.Printf("❌ Query count failed: %v\n", err)
		return
	}

	fmt.Printf("✅ Pending verifications in DB: %d\n", count)

	if count == 0 {
		fmt.Println("No payments to verify - need to create test payment data")
		return
	}

	// Get actual records
	rows, err := conn.Query(context.Background(), `
		SELECT pt.transaction_id, pt.user_id, pt.customer_name, pt.status, pt.is_verified
		FROM payment_transactions pt
		WHERE pt.status = 'success' AND pt.is_verified = FALSE
		LIMIT 5
	`)
	if err != nil {
		fmt.Printf("❌ Query records failed: %v\n", err)
		return
	}
	defer rows.Close()

	fmt.Println("\nPending verification records:")
	for rows.Next() {
		var transID string
		var userID int
		var customerName string
		var status string
		var isVerified bool

		err := rows.Scan(&transID, &userID, &customerName, &status, &isVerified)
		if err != nil {
			fmt.Printf("❌ Scan error: %v\n", err)
			continue
		}

		fmt.Printf("  %s | UserID: %d | Name: %s | Status: %s | Verified: %v\n",
			transID, userID, customerName, status, isVerified)
	}
}
