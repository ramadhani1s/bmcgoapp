package repositories

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"bmcgoapp-backend/config"
)

type PaymentVerificationItem struct {
	TransactionID      string     `json:"transaction_id"`
	UserID             int        `json:"user_id"`
	StudentName        string     `json:"student_name"`
	ClassName          string     `json:"class_name"`
	SchoolName         string     `json:"school_name"`
	Address            string     `json:"address"`
	RegisteredWhatsApp string     `json:"registered_whatsapp"`
	PackageID          string     `json:"package_id"`
	PackageTitle       string     `json:"package_title"`
	Amount             int64      `json:"amount"`
	Status             string     `json:"status"`
	PaymentType        string     `json:"payment_type"`
	CustomerName       string     `json:"customer_name"`
	CustomerEmail      string     `json:"customer_email"`
	CustomerPhone      string     `json:"customer_phone"`
	UserStatus         string     `json:"user_status"`
	IsVerified         bool       `json:"is_verified"`
	VerifiedAt         *time.Time `json:"verified_at,omitempty"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
	VerifiedByAdmin    *int       `json:"verified_by_admin,omitempty"`
}

type PaymentVerificationOverview struct {
	Items    []PaymentVerificationItem
	Waiting  int
	Approved int
	Rejected int
}

func GetVerificationStatus(ctx context.Context, userID int) (string, bool, *time.Time, error) {
	var userStatus string
	var hasVerifiedPayment bool
	var verifiedAt sql.NullTime

	err := config.DB.QueryRow(ctx, `
		SELECT
			COALESCE(
				(SELECT status::TEXT
				 FROM users
				 WHERE id = $1),
				''
			) AS user_status,

			EXISTS(
				SELECT 1
				FROM payment_transactions
				WHERE user_id = $1
				AND COALESCE(is_verified, FALSE) = TRUE
			) AS has_verified_payment,

			(
				SELECT MAX(verified_at)
				FROM payment_transactions
				WHERE user_id = $1
				AND COALESCE(is_verified, FALSE) = TRUE
			) AS latest_verified_at
	`, userID).Scan(
		&userStatus,
		&hasVerifiedPayment,
		&verifiedAt,
	)

	if err != nil {
		fmt.Println("GET VERIFICATION STATUS ERROR:", err)
		return "", false, nil, err
	}

	var verifiedAtPtr *time.Time
	if verifiedAt.Valid {
		verifiedAtPtr = &verifiedAt.Time
	}

	fmt.Println(
		"VERIFICATION STATUS:",
		"userID=", userID,
		"userStatus=", userStatus,
		"hasVerifiedPayment=", hasVerifiedPayment,
	)

	return strings.TrimSpace(userStatus), hasVerifiedPayment, verifiedAtPtr, nil
}

func GetPendingPaymentVerifications(ctx context.Context) ([]PaymentVerificationItem, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT DISTINCT ON (pt.user_id)
			pt.transaction_id,
			pt.user_id,
			COALESCE(NULLIF(u.nama, ''), pt.customer_name) AS student_name,
			COALESCE(s.kelas, '') AS class_name,
			COALESCE(s.asal_sekolah, '') AS school_name,
			'' AS address,
			COALESCE(pt.customer_phone, '') AS registered_whatsapp,
			pt.package_id,
			pt.package_title,
			pt.amount,
			pt.status,
			COALESCE(pt.payment_type, '') AS payment_type,
			pt.customer_name,
			pt.customer_email,
			pt.customer_phone,
			COALESCE(u.status::VARCHAR, '') AS user_status,
			COALESCE(pt.is_verified, FALSE) AS is_verified,
			pt.verified_at,
			pt.created_at,
			pt.updated_at,
			pt.verified_by_admin
		FROM payment_transactions pt
		LEFT JOIN users u ON u.id = pt.user_id
		LEFT JOIN siswa s ON s.user_id = pt.user_id
		WHERE pt.status = 'success'
		ORDER BY pt.user_id, pt.created_at DESC
		LIMIT 100
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]PaymentVerificationItem, 0)
	for rows.Next() {
		item := PaymentVerificationItem{}
		if err := rows.Scan(
			&item.TransactionID, &item.UserID,
			&item.StudentName, &item.ClassName, &item.SchoolName,
			&item.Address, &item.RegisteredWhatsApp, &item.PackageID, &item.PackageTitle,
			&item.Amount, &item.Status, &item.PaymentType,
			&item.CustomerName, &item.CustomerEmail, &item.CustomerPhone,
			&item.UserStatus, &item.IsVerified, &item.VerifiedAt,
			&item.CreatedAt, &item.UpdatedAt, &item.VerifiedByAdmin,
		); err != nil {
			continue
		}
		items = append(items, item)
	}

	return items, nil
}

// GetPaymentVerificationsWithFilter returns payment verifications filtered by status
// status can be: "pending" (not verified), "approved" (verified), or "all" (both)
func GetPaymentVerificationsWithFilter(ctx context.Context, filterStatus string) ([]PaymentVerificationItem, error) {
	var whereClause string

	switch filterStatus {
	case "pending":
		whereClause = "WHERE pt.status = 'success' AND COALESCE(pt.is_verified, FALSE) = FALSE"
	case "approved":
		whereClause = "WHERE pt.status = 'success' AND COALESCE(pt.is_verified, FALSE) = TRUE"
	default:
		whereClause = "WHERE pt.status = 'success'"
	}

	query := `
		SELECT DISTINCT ON (pt.user_id)
			pt.transaction_id,
			pt.user_id,

			COALESCE(
				NULLIF(u.nama, ''),
				COALESCE(pt.customer_name, '')
			) AS student_name,

			COALESCE(s.kelas, '') AS class_name,
			COALESCE(s.asal_sekolah, '') AS school_name,

			'' AS address,

			COALESCE(pt.customer_phone, '') AS registered_whatsapp,

			COALESCE(pt.package_id, '') AS package_id,
			COALESCE(pt.package_title, '') AS package_title,

			COALESCE(pt.amount, 0) AS amount,
			COALESCE(pt.status, '') AS status,
			COALESCE(pt.payment_type, '') AS payment_type,

			COALESCE(pt.customer_name, '') AS customer_name,
			COALESCE(pt.customer_email, '') AS customer_email,
			COALESCE(pt.customer_phone, '') AS customer_phone,

			COALESCE(u.status::TEXT, '') AS user_status,

			COALESCE(pt.is_verified, FALSE) AS is_verified,
			pt.verified_at,

			COALESCE(pt.created_at, NOW()) AS created_at,
			COALESCE(pt.updated_at, NOW()) AS updated_at,

			pt.verified_by_admin

		FROM payment_transactions pt

		LEFT JOIN users u
			ON u.id = pt.user_id

		LEFT JOIN siswa s
			ON s.user_id = pt.user_id

		` + whereClause + `

		ORDER BY pt.user_id, pt.created_at DESC
		LIMIT 100
	`

	fmt.Println("PAYMENT QUERY:", query)

	rows, err := config.DB.Query(ctx, query)
	if err != nil {
		fmt.Println("QUERY ERROR:", err)
		return nil, err
	}
	defer rows.Close()

	items := make([]PaymentVerificationItem, 0)

	for rows.Next() {
		item := PaymentVerificationItem{}

		err := rows.Scan(
			&item.TransactionID,
			&item.UserID,

			&item.StudentName,
			&item.ClassName,
			&item.SchoolName,

			&item.Address,
			&item.RegisteredWhatsApp,

			&item.PackageID,
			&item.PackageTitle,

			&item.Amount,
			&item.Status,
			&item.PaymentType,

			&item.CustomerName,
			&item.CustomerEmail,
			&item.CustomerPhone,

			&item.UserStatus,
			&item.IsVerified,
			&item.VerifiedAt,

			&item.CreatedAt,
			&item.UpdatedAt,
			&item.VerifiedByAdmin,
		)

		if err != nil {
			fmt.Println("SCAN ERROR:", err)
			continue
		}

		items = append(items, item)
	}

	fmt.Println("TOTAL ITEMS:", len(items))

	return items, nil
}
func ApprovePaymentVerification(ctx context.Context, transactionID string, adminID int) (int, error) {
	var userID int

	err := config.DB.QueryRow(ctx, `
		SELECT user_id FROM payment_transactions WHERE transaction_id = $1
	`, transactionID).Scan(&userID)
	if err != nil {
		return 0, err
	}

	// Update payment transaction and ensure it was applied
	ct, err := config.DB.Exec(ctx, `
		UPDATE payment_transactions
		SET is_verified = TRUE,
			verified_at = NOW(),
			verified_by_admin = $1,
			updated_at = NOW()
		WHERE transaction_id = $2
	`, adminID, transactionID)
	if err != nil {
		return 0, fmt.Errorf("failed update payment_transactions: %w", err)
	}
	if ct.RowsAffected() == 0 {
		return 0, fmt.Errorf("no payment_transactions row updated for transaction_id=%s", transactionID)
	}

	// Update user status and ensure it was applied
	ct2, err := config.DB.Exec(ctx, `
		UPDATE users
		SET status = 'aktif'
		WHERE id = $1
	`, userID)
	if err != nil {
		return 0, fmt.Errorf("failed update users status: %w", err)
	}
	if ct2.RowsAffected() == 0 {
		return 0, fmt.Errorf("no users row updated for id=%d", userID)
	}

	return userID, nil
}
func RejectPaymentVerification(ctx context.Context, transactionID string, adminID int) error {
	_, err := config.DB.Exec(ctx, `
		UPDATE payment_transactions
		SET is_verified = FALSE,
			verified_at = NOW(),
			verified_by_admin = $1,
			status = 'failed',
			updated_at = NOW()
		WHERE transaction_id = $2
	`, adminID, transactionID)

	return err
}
func GetPaymentVerificationOverview(ctx context.Context) (PaymentVerificationOverview, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT
			pt.transaction_id,
			pt.user_id,
			COALESCE(pt.customer_name, '') AS student_name,
			'' AS class_name,
			'' AS school_name,
			'' AS address,
			COALESCE(pt.customer_phone, '') AS registered_whatsapp,
			COALESCE(pt.package_id, '') AS package_id,
			COALESCE(pt.package_title, '') AS package_title,
			COALESCE(pt.amount, 0) AS amount,
			COALESCE(pt.status, '') AS status,
			COALESCE(pt.payment_type, '') AS payment_type,
			COALESCE(pt.customer_name, '') AS customer_name,
			COALESCE(pt.customer_email, '') AS customer_email,
			COALESCE(pt.customer_phone, '') AS customer_phone,
			'' AS user_status,
			COALESCE(pt.is_verified, FALSE) AS is_verified,
			pt.verified_at,
			COALESCE(pt.created_at, NOW()) AS created_at,
			COALESCE(pt.updated_at, NOW()) AS updated_at,
			pt.verified_by_admin
		FROM payment_transactions pt
		WHERE pt.status IN ('success', 'pending', 'failed', 'cancel', 'deny', 'expire')
		ORDER BY pt.created_at DESC
		LIMIT 100
	`)
	if err != nil {
		return PaymentVerificationOverview{}, err
	}
	defer rows.Close()

	overview := PaymentVerificationOverview{Items: make([]PaymentVerificationItem, 0)}
	for rows.Next() {
		item := PaymentVerificationItem{}
		if err := rows.Scan(
			&item.TransactionID, &item.UserID,
			&item.StudentName, &item.ClassName, &item.SchoolName,
			&item.Address, &item.RegisteredWhatsApp, &item.PackageID, &item.PackageTitle,
			&item.Amount, &item.Status, &item.PaymentType,
			&item.CustomerName, &item.CustomerEmail, &item.CustomerPhone,
			&item.UserStatus, &item.IsVerified, &item.VerifiedAt,
			&item.CreatedAt, &item.UpdatedAt, &item.VerifiedByAdmin,
		); err != nil {
			continue
		}
		item.Status = strings.TrimSpace(item.Status)
		if item.IsVerified {
			overview.Approved++
		} else if strings.EqualFold(item.Status, "success") {
			overview.Waiting++
		} else {
			overview.Rejected++
		}
		overview.Items = append(overview.Items, item)
	}

	return overview, nil
}
