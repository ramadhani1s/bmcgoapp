package repositories

import (
	"context"
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
	var verifiedAt *time.Time
	err := config.DB.QueryRow(ctx, `
		SELECT
			COALESCE((SELECT status FROM users WHERE id = $1), '') AS user_status,
			EXISTS(
				SELECT 1
				FROM payment_transactions
				WHERE user_id = $1 AND COALESCE(is_verified, FALSE) = TRUE
			) AS has_verified_payment,
			(
				SELECT MAX(verified_at)
				FROM payment_transactions
				WHERE user_id = $1 AND COALESCE(is_verified, FALSE) = TRUE
			) AS latest_verified_at
	`, userID).Scan(&userStatus, &hasVerifiedPayment, &verifiedAt)
	if err != nil {
		return "", false, nil, err
	}

	return strings.TrimSpace(userStatus), hasVerifiedPayment, verifiedAt, nil
}

func GetPendingPaymentVerifications(ctx context.Context) ([]PaymentVerificationItem, error) {
	rows, err := config.DB.Query(ctx, `
		SELECT DISTINCT ON (pt.user_id)
			pt.transaction_id,
			pt.user_id,
			COALESCE(pt.customer_name, '') AS student_name,
			'' AS class_name,
			'' AS school_name,
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
			'' AS user_status,
			COALESCE(pt.is_verified, FALSE) AS is_verified,
			pt.verified_at,
			pt.created_at,
			pt.updated_at,
			pt.verified_by_admin
		FROM payment_transactions pt
		WHERE pt.status = 'success' AND COALESCE(pt.is_verified, FALSE) = FALSE
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

func ApprovePaymentVerification(ctx context.Context, transactionID string, adminID int) (int, error) {
	var userID int
	err := config.DB.QueryRow(ctx, `
		SELECT user_id FROM payment_transactions WHERE transaction_id = $1
	`, transactionID).Scan(&userID)
	if err != nil {
		return 0, err
	}

	_, err = config.DB.Exec(ctx, `
		UPDATE payment_transactions
		SET is_verified = TRUE,
			verified_at = NOW(),
			verified_by_admin = $1,
			updated_at = NOW()
		WHERE transaction_id = $2
	`, adminID, transactionID)
	if err != nil {
		return 0, err
	}

	_, err = config.DB.Exec(ctx, `
		UPDATE users
		SET status = 'aktif'
		WHERE id = $1
	`, userID)
	if err != nil {
		return 0, err
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
