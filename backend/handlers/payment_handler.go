package handlers

import (
	"bmcgoapp-backend/config"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"bmcgoapp-backend/repositories"

	"github.com/gin-gonic/gin"
	"github.com/midtrans/midtrans-go"
	"github.com/midtrans/midtrans-go/coreapi"
	"github.com/midtrans/midtrans-go/snap"
)

// PaymentRequest struct untuk menerima data pembayaran
type PaymentRequest struct {
	PackageID     string `json:"package_id" binding:"required"`
	PackageTitle  string `json:"package_title" binding:"required"`
	Amount        string `json:"amount" binding:"required"`
	CustomerName  string `json:"customer_name" binding:"required"`
	CustomerEmail string `json:"customer_email" binding:"required"`
	CustomerPhone string `json:"customer_phone"`
}

// PaymentResponse struct untuk response pembayaran
type PaymentResponse struct {
	Token         string `json:"token"`
	RedirectURL   string `json:"redirect_url"`
	TransactionID string `json:"transaction_id"`
	Status        string `json:"status"`
}

type PaymentHistoryItem struct {
	TransactionID string    `json:"transaction_id"`
	PackageID     string    `json:"package_id"`
	PackageTitle  string    `json:"package_title"`
	Amount        int64     `json:"amount"`
	Status        string    `json:"status"`
	PaymentType   string    `json:"payment_type"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

func normalizeStatus(status string) string {
	s := strings.ToLower(strings.TrimSpace(status))
	switch s {
	case "settlement", "capture", "success":
		return "success"
	case "pending":
		return "pending"
	case "deny", "cancel", "expire", "failure", "failed":
		return "failed"
	default:
		return s
	}
}

func InitMidtrans() {
	midtrans.ServerKey = "Mid-server-QRDtut5gyc07B9FjYtz4-fIQ"
	midtrans.ClientKey = "Mid-client-oGUyoloFZJXYlklg"
	midtrans.Environment = midtrans.Sandbox
	if notifyURL := strings.TrimSpace(os.Getenv("MIDTRANS_NOTIFICATION_URL")); notifyURL != "" {
		midtrans.SetPaymentAppendNotification(notifyURL)
	}
}

func getCurrentPhone(ctx *gin.Context, userID int) string {
	var phone string
	err := config.DB.QueryRow(ctx.Request.Context(), `SELECT COALESCE(NULLIF(phone_number, ''), '') FROM users WHERE id = $1`, userID).Scan(&phone)
	if err != nil || strings.TrimSpace(phone) == "" {
		return "08123456789"
	}
	return phone
}

func savePaymentTransaction(ctx *gin.Context, transactionID string, userID int, req PaymentRequest, amount int64, status string, paymentType string) {
	_, _ = config.DB.Exec(ctx.Request.Context(), `
		INSERT INTO payment_transactions (
			transaction_id, user_id, package_id, package_title, amount, status,
			payment_type, customer_name, customer_email, customer_phone, created_at, updated_at
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,NOW(),NOW())
		ON CONFLICT (transaction_id) DO UPDATE SET
			package_id = EXCLUDED.package_id,
			package_title = EXCLUDED.package_title,
			amount = EXCLUDED.amount,
			status = EXCLUDED.status,
			payment_type = COALESCE(NULLIF(EXCLUDED.payment_type, ''), payment_transactions.payment_type),
			customer_name = EXCLUDED.customer_name,
			customer_email = EXCLUDED.customer_email,
			customer_phone = EXCLUDED.customer_phone,
			updated_at = NOW()
	`, transactionID, userID, req.PackageID, req.PackageTitle, amount, status, paymentType, req.CustomerName, req.CustomerEmail, req.CustomerPhone)
}

func loadPaymentHistory(ctx *gin.Context, userID int, status string) ([]PaymentHistoryItem, error) {
	query := `
		SELECT transaction_id, package_id, package_title, amount, status,
		       COALESCE(payment_type, ''), created_at, updated_at
		FROM payment_transactions
		WHERE user_id = $1`
	args := []interface{}{userID}
	if status != "" {
		query += ` AND LOWER(status) = $2`
		args = append(args, status)
	}
	query += ` ORDER BY created_at DESC LIMIT 100`

	rows, err := config.DB.Query(ctx.Request.Context(), query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]PaymentHistoryItem, 0)
	for rows.Next() {
		item := PaymentHistoryItem{}
		if err := rows.Scan(&item.TransactionID, &item.PackageID, &item.PackageTitle, &item.Amount, &item.Status, &item.PaymentType, &item.CreatedAt, &item.UpdatedAt); err != nil {
			continue
		}
		item.Status = normalizeStatus(item.Status)
		items = append(items, item)
	}
	return items, rows.Err()
}

// CreateTransaction membuat transaction di Midtrans
func CreateTransaction(c *gin.Context) {
	var req PaymentRequest
	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid request data", "error": err.Error()})
		return
	}

	userIDValue, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
	userIDInt, ok := userIDValue.(int)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	if strings.TrimSpace(req.CustomerPhone) == "" {
		req.CustomerPhone = getCurrentPhone(c, userIDInt)
	}

	amount, err := strconv.ParseInt(req.Amount, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid amount format"})
		return
	}

	transactionID := fmt.Sprintf("BMC-%d-%s-%d", userIDInt, req.PackageID, time.Now().UnixMilli())

	snapReq := &snap.Request{
		TransactionDetails: midtrans.TransactionDetails{OrderID: transactionID, GrossAmt: amount},
		CustomerDetail:     &midtrans.CustomerDetails{FName: req.CustomerName, Email: req.CustomerEmail, Phone: req.CustomerPhone},
		Items: &[]midtrans.ItemDetails{{
			ID: req.PackageID, Price: amount, Qty: 1, Name: req.PackageTitle,
		}},
	}

	snapResp, midtransErr := snap.CreateTransaction(snapReq)
	if midtransErr != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to create transaction", "error": midtransErr.Error()})
		return
	}

	savePaymentTransaction(c, transactionID, userIDInt, req, amount, "pending", "")

	c.JSON(http.StatusOK, gin.H{"message": "Transaction created successfully", "data": PaymentResponse{Token: snapResp.Token, RedirectURL: snapResp.RedirectURL, TransactionID: transactionID, Status: "pending"}})
}

// CheckPaymentStatus mengecek status pembayaran
func CheckPaymentStatus(c *gin.Context) {
	transactionID := c.Param("transactionId")
	if strings.TrimSpace(transactionID) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Transaction ID is required"})
		return
	}

	resp, err := coreapi.CheckTransaction(transactionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to check transaction status", "error": err.Error()})
		return
	}

	normalizedStatus := normalizeStatus(resp.TransactionStatus)
	_, _ = config.DB.Exec(c.Request.Context(), `
		UPDATE payment_transactions
		SET status = $1,
			payment_type = COALESCE(NULLIF($2, ''), payment_type),
			updated_at = NOW()
		WHERE transaction_id = $3
	`, normalizedStatus, resp.PaymentType, transactionID)

	c.JSON(http.StatusOK, gin.H{
		"message": "Transaction status retrieved",
		"data": gin.H{
			"transaction_id":     resp.TransactionID,
			"transaction_status": resp.TransactionStatus,
			"status_message":     resp.StatusMessage,
			"payment_type":       resp.PaymentType,
			"fraud_status":       resp.FraudStatus,
		},
	})
}

// FinishTransaction menyelesaikan transaction
func FinishTransaction(c *gin.Context) {
	var req struct {
		TransactionID string `json:"transaction_id" binding:"required"`
		Status        string `json:"status" binding:"required"`
	}

	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid request data"})
		return
	}

	status := normalizeStatus(req.Status)
	_, _ = config.DB.Exec(c.Request.Context(), `
		UPDATE payment_transactions
		SET status = $1, updated_at = NOW()
		WHERE transaction_id = $2
	`, status, req.TransactionID)

	c.JSON(http.StatusOK, gin.H{"message": "Transaction finished", "data": gin.H{"transaction_id": req.TransactionID, "status": status}})
}

// PaymentNotification menerima notifikasi dari Midtrans
func PaymentNotification(c *gin.Context) {
	var notification map[string]interface{}
	if err := c.BindJSON(&notification); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Invalid notification data"})
		return
	}

	transactionID, _ := notification["order_id"].(string)
	transactionStatus, _ := notification["transaction_status"].(string)
	paymentType, _ := notification["payment_type"].(string)
	status := normalizeStatus(transactionStatus)

	if strings.TrimSpace(transactionID) != "" {
		_, _ = config.DB.Exec(c.Request.Context(), `
			UPDATE payment_transactions
			SET status = $1,
				payment_type = COALESCE(NULLIF($2, ''), payment_type),
				updated_at = NOW()
			WHERE transaction_id = $3
		`, status, paymentType, transactionID)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Notification received", "order_id": transactionID, "transaction_status": status})
}

// GetPaymentHistory daftar riwayat pembayaran user
func GetPaymentHistory(c *gin.Context) {
	userIDValue, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
	userIDInt, ok := userIDValue.(int)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	status := normalizeStatus(c.Query("status"))
	history, err := loadPaymentHistory(c, userIDInt, status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to load payment history", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Payment history retrieved", "data": history})
}

// GetVerificationStatus cek apakah user sudah terverifikasi
func GetVerificationStatus(c *gin.Context) {
	userIDValue, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
	userIDInt, ok := userIDValue.(int)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	userStatus, hasVerifiedPayment, verifiedAt, err := repositories.GetVerificationStatus(c.Request.Context(), userIDInt)

	var isVerified bool
	var verifiedAt *time.Time
	err := config.DB.QueryRow(c.Request.Context(), `
		SELECT COALESCE(is_verified, FALSE), verified_at
		FROM payment_transactions
		WHERE user_id = $1 AND LOWER(status) IN ('success', 'settlement', 'capture')
		ORDER BY created_at DESC
		LIMIT 1
	`, userIDInt).Scan(&isVerified, &verifiedAt)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"message": "Payment verification status", "is_verified": false, "verified_at": nil, "can_access": false})
		return
	}

	isUserActive := strings.EqualFold(strings.TrimSpace(userStatus), "aktif")
	canAccess := isUserActive || hasVerifiedPayment

	// Self-heal: jika pembayaran sudah diverifikasi tapi user belum aktif, aktifkan akun.
	if hasVerifiedPayment && !isUserActive {
		_, _ = config.DB.Exec(c.Request.Context(), `
			UPDATE users
			SET status = 'aktif'
			WHERE id = $1
		`, userIDInt)
		isUserActive = true
		canAccess = true
		userStatus = "aktif"
	}

	c.JSON(http.StatusOK, gin.H{
		"message":        "Payment verification status",
		"is_verified":    hasVerifiedPayment,
		"verified_at":    verifiedAt,
		"can_access":     canAccess,
		"user_status":    userStatus,
		"is_user_active": isUserActive,
	})
}

type PendingVerificationItem = repositories.PaymentVerificationItem
	c.JSON(http.StatusOK, gin.H{"message": "Payment verification status", "is_verified": isVerified, "verified_at": verifiedAt, "can_access": isVerified})
}

// PendingVerificationItem untuk response list verifikasi pending
type PendingVerificationItem struct {
	TransactionID   string     `json:"transaction_id"`
	UserID          int        `json:"user_id"`
	StudentName     string     `json:"student_name"`
	StudentEmail    string     `json:"student_email"`
	StudentPhone    string     `json:"student_phone"`
	SchoolName      string     `json:"school_name"`
	ClassName       string     `json:"class_name"`
	PackageTitle    string     `json:"package_title"`
	Amount          int64      `json:"amount"`
	PaymentType     string     `json:"payment_type"`
	CreatedAt       time.Time  `json:"created_at"`
	Status          string     `json:"status"`
	IsVerified      bool       `json:"is_verified"`
	VerifiedAt      *time.Time `json:"verified_at,omitempty"`
	VerifiedByAdmin *int       `json:"verified_by_admin,omitempty"`
}

// GetPendingPaymentVerifications mendapatkan list pembayaran yang belum diverifikasi (untuk admin)
func GetPendingPaymentVerifications(c *gin.Context) {
	_, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	items, err := repositories.GetPendingPaymentVerifications(c.Request.Context())
	rows, err := config.DB.Query(c.Request.Context(), `
		SELECT DISTINCT ON (pt.user_id)
			pt.transaction_id,
			pt.user_id,
			COALESCE(pt.customer_name, NULLIF(u.nama, ''), '') AS student_name,
			COALESCE(pt.customer_email, NULLIF(u.email, ''), '') AS student_email,
			COALESCE(pt.customer_phone, NULLIF(u.phone_number, ''), '') AS student_phone,
			COALESCE(s.asal_sekolah, '') AS school_name,
			COALESCE(s.kelas, '') AS class_name,
			pt.package_title,
			pt.amount,
			COALESCE(pt.payment_type, '') AS payment_type,
			pt.created_at,
			pt.status,
			COALESCE(pt.is_verified, FALSE) AS is_verified,
			pt.verified_at,
			pt.verified_by_admin
		FROM payment_transactions pt
		LEFT JOIN users u ON u.id = pt.user_id
		LEFT JOIN siswa s ON s.user_id = pt.user_id
		WHERE pt.status = 'success' AND COALESCE(pt.is_verified, FALSE) = FALSE
		ORDER BY pt.user_id, pt.created_at DESC
		LIMIT 100
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to load pending verifications", "error": err.Error()})
		return
	}
	for i := range items {
		items[i].Status = normalizeStatus(items[i].Status)

	defer rows.Close()

	items := make([]PendingVerificationItem, 0)
	for rows.Next() {
		item := PendingVerificationItem{}
		if err := rows.Scan(
			&item.TransactionID, &item.UserID,
			&item.StudentName, &item.StudentEmail, &item.StudentPhone,
			&item.SchoolName, &item.ClassName,
			&item.PackageTitle, &item.Amount, &item.PaymentType,
			&item.CreatedAt, &item.Status, &item.IsVerified,
			&item.VerifiedAt, &item.VerifiedByAdmin,
		); err != nil {
			continue
		}
		item.Status = normalizeStatus(item.Status)
		items = append(items, item)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Pending verifications retrieved", "data": items})
}

// ApprovePaymentVerification menyetujui pembayaran dan mengaktifkan akun siswa
func ApprovePaymentVerification(c *gin.Context) {
	adminIDValue, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
	adminID, ok := adminIDValue.(int)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	transactionID := c.Param("transactionId")
	if strings.TrimSpace(transactionID) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Transaction ID is required"})
		return
	}

	userID, err := repositories.ApprovePaymentVerification(c.Request.Context(), transactionID, adminID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"message": "Transaction not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Payment verification approved and user account activated",
		"data": gin.H{
			"transaction_id": transactionID,
			"user_id":        userID,
			"is_verified":    true,
		},
	})
}

// RejectPaymentVerification menolak pembayaran
func RejectPaymentVerification(c *gin.Context) {
	adminIDValue, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}
	adminID, ok := adminIDValue.(int)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	transactionID := c.Param("transactionId")
	if strings.TrimSpace(transactionID) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Transaction ID is required"})
		return
	}

	err := repositories.RejectPaymentVerification(c.Request.Context(), transactionID, adminID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to reject verification", "error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Payment verification rejected",
		"data": gin.H{
			"transaction_id": transactionID,
			"status":         "failed",
		},
	})
}


// DeletePaymentVerification menghapus data verifikasi/pembayaran
func DeletePaymentVerification(c *gin.Context) {
	_, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	transactionID := c.Param("transactionId")
	if strings.TrimSpace(transactionID) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Transaction ID is required"})
		return
	}

	commandTag, err := config.DB.Exec(c.Request.Context(), `
		DELETE FROM payment_transactions
		WHERE transaction_id = $1
	`, transactionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to delete verification data", "error": err.Error()})
		return
	}

	if commandTag.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"message": "Transaction not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Payment verification deleted",
		"data": gin.H{
			"transaction_id": transactionID,
		},
	})
}

// GetPaymentVerificationOverview mendapatkan overview verifikasi pembayaran (untuk admin dashboard)
func GetPaymentVerificationOverview(c *gin.Context) {
	_, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	overview, err := repositories.GetPaymentVerificationOverview(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to load overview", "error": err.Error()})
		return
	}
	items := overview.Items
	waiting := overview.Waiting
	approved := overview.Approved
	rejected := overview.Rejected

	c.JSON(http.StatusOK, gin.H{
		"message": "Overview retrieved",
		"data": gin.H{
			"waiting":  waiting,
			"approved": approved,
			"rejected": rejected,
			"items":    items,
		},
	})
}
