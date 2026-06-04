package handlers

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/repositories"
	"bmcgoapp-backend/utils"
	"context"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

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
	Token                string `json:"token,omitempty"`
	RedirectURL          string `json:"redirect_url,omitempty"`
	TransactionID        string `json:"transaction_id"`
	Status               string `json:"status"`
	PaymentType          string `json:"payment_type,omitempty"`
	VirtualAccountBank   string `json:"virtual_account_bank,omitempty"`
	VirtualAccountNumber string `json:"virtual_account_number,omitempty"`
	BillKey              string `json:"bill_key,omitempty"`
	BillerCode           string `json:"biller_code,omitempty"`
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
	if notifyURL := resolveMidtransNotificationURL(); notifyURL != "" {
		midtrans.SetPaymentAppendNotification(notifyURL)
	}
}

func resolveMidtransNotificationURL() string {
	if notifyURL := strings.TrimSpace(os.Getenv("MIDTRANS_NOTIFICATION_URL")); notifyURL != "" {
		return notifyURL
	}

	if baseURL := strings.TrimSpace(os.Getenv("BACKEND_PUBLIC_BASE_URL")); baseURL != "" {
		return strings.TrimRight(baseURL, "/") + "/payment/notification"
	}

	return "http://localhost:8080/payment/notification"
}

func getCurrentPhone(ctx *gin.Context, userID int) string {
	var phone string
	err := config.DB.QueryRow(ctx.Request.Context(), `SELECT COALESCE(NULLIF(phone_number, ''), '') FROM users WHERE id = $1`, userID).Scan(&phone)
	if err != nil || strings.TrimSpace(phone) == "" {
		return "08123456789"
	}
	return phone
}

func resolveBankTransferBank() midtrans.Bank {
	switch strings.ToLower(strings.TrimSpace(os.Getenv("MIDTRANS_VA_BANK"))) {
	case "mandiri":
		return midtrans.BankMandiri
	case "bni":
		return midtrans.BankBni
	case "bri":
		return midtrans.BankBri
	case "permata":
		return midtrans.BankPermata
	case "maybank":
		return midtrans.BankMaybank
	default:
		return midtrans.BankBca
	}
}

func extractPaymentDetails(resp *coreapi.ChargeResponse) (bank string, vaNumber string, billKey string, billerCode string) {
	if resp == nil {
		return "", "", "", ""
	}

	bank = strings.TrimSpace(resp.Bank)
	if bank == "" {
		bank = strings.TrimSpace(resp.PaymentType)
	}

	vaNumber = strings.TrimSpace(resp.PermataVaNumber)
	if vaNumber == "" {
		for _, item := range resp.VaNumbers {
			if strings.TrimSpace(item.VANumber) != "" {
				vaNumber = strings.TrimSpace(item.VANumber)
				if bank == "" {
					bank = strings.TrimSpace(item.Bank)
				}
				break
			}
		}
	}

	billKey = strings.TrimSpace(resp.BillKey)
	billerCode = strings.TrimSpace(resp.BillerCode)
	return
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

	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	successPath := strings.Replace(c.Request.URL.Path, "/create-transaction", "/success", 1)
	successURL := fmt.Sprintf("%s://%s%s", scheme, c.Request.Host, successPath)

	snapReq := &snap.Request{
		TransactionDetails: midtrans.TransactionDetails{
			OrderID:  transactionID,
			GrossAmt: amount,
		},
		CustomerDetail: &midtrans.CustomerDetails{
			FName: req.CustomerName,
			Email: req.CustomerEmail,
			Phone: req.CustomerPhone,
		},
		Items: &[]midtrans.ItemDetails{{
			ID:    req.PackageID,
			Name:  req.PackageTitle,
			Price: amount,
			Qty:   1,
		}},
		Callbacks: &snap.Callbacks{
			Finish: successURL,
		},
	}

	client := snap.Client{}
	client.New(midtrans.ServerKey, midtrans.Sandbox)
	snapResp, midtransErr := client.CreateTransaction(snapReq)
	if midtransErr != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to create snap transaction", "error": midtransErr.GetMessage()})
		return
	}

	status := "pending"
	savePaymentTransaction(c, transactionID, userIDInt, req, amount, status, "snap")

	c.JSON(http.StatusOK, gin.H{"message": "Transaction created successfully", "data": PaymentResponse{
		TransactionID: transactionID,
		Status:        status,
		Token:         snapResp.Token,
		RedirectURL:   snapResp.RedirectURL,
	}})
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

// PaymentSuccessPage menampilkan halaman sukses statis
func PaymentSuccessPage(c *gin.Context) {
	html := `<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pembayaran Selesai</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f5f5f5; margin: 0; text-align: center; padding: 20px; }
        .card { background: white; padding: 40px 30px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); max-width: 400px; width: 100%; }
        .icon { font-size: 60px; margin-bottom: 20px; }
        h1 { color: #2D8B3A; font-size: 24px; margin-bottom: 10px; }
        p { color: #555; font-size: 16px; line-height: 1.5; margin-bottom: 25px; }
        .instruction { background-color: #FFF3CD; color: #856404; padding: 15px; border-radius: 8px; font-size: 14px; font-weight: 600; border: 1px solid #FFEEBA; }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">✅</div>
        <h1>Pembayaran Diproses</h1>
        <p>Transaksi Anda telah kami terima dan sedang diverifikasi oleh sistem.</p>
        <div class="instruction">
            💡 Silakan tekan tombol X (Silang) atau Done di sudut layar untuk kembali ke aplikasi.
        </div>
    </div>
</body>
</html>`
	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(html))
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

	// Auto-sync status dari Midtrans khusus untuk simulasi localhost
	autoSyncPendingTransactions(c.Request.Context())

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
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Payment verification status error", "error": err.Error()})
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

func autoSyncPendingTransactions(ctx context.Context) {
	rows, err := config.DB.Query(ctx, `SELECT transaction_id FROM payment_transactions WHERE status = 'pending' AND COALESCE(is_verified, FALSE) = FALSE`)
	if err != nil {
		return
	}
	defer rows.Close()

	var tIDs []string
	for rows.Next() {
		var tid string
		if err := rows.Scan(&tid); err == nil {
			tIDs = append(tIDs, tid)
		}
	}

	for _, tid := range tIDs {
		resp, checkErr := coreapi.CheckTransaction(tid)
		if checkErr == nil && resp.TransactionStatus != "" {
			newStatus := normalizeStatus(resp.TransactionStatus)
			if newStatus != "pending" {
				_, _ = config.DB.Exec(ctx, `
					UPDATE payment_transactions
					SET status = $1, payment_type = COALESCE(NULLIF($2, ''), payment_type), updated_at = NOW()
					WHERE transaction_id = $3
				`, newStatus, resp.PaymentType, tid)
			}
		}
	}
}

// GetPendingPaymentVerifications mendapatkan list pembayaran yang belum diverifikasi (untuk admin)
func GetPendingPaymentVerifications(c *gin.Context) {
	_, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	// Get filter parameter from query: pending, approved, or all
	filter := c.DefaultQuery("filter", "pending")

	// Auto-sync pending transactions dengan Midtrans (Sangat berguna untuk testing di Localhost)
	autoSyncPendingTransactions(c.Request.Context())

	items, err := repositories.GetPaymentVerificationsWithFilter(c.Request.Context(), filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Failed to load verifications", "error": err.Error()})
		return
	}

	for i := range items {
		items[i].Status = normalizeStatus(items[i].Status)
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Verifications retrieved",
		"filter":  filter,
		"data":    items,
	})
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
		// Log error untuk debugging
		fmt.Printf("ApprovePaymentVerification error: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Gagal melakukan approval pembayaran dan aktivasi akun siswa",
			"error":   err.Error(),
		})
		return
	}

	// Log current DB state for this transaction/user to aid debugging
	var dbUserStatus string
	var dbIsVerified bool
	var dbVerifiedByAdmin *int
	var dbVerifiedAt *time.Time

	_ = config.DB.QueryRow(c.Request.Context(), `
		SELECT COALESCE(status, '') FROM users WHERE id = $1
	`, userID).Scan(&dbUserStatus)

	_ = config.DB.QueryRow(c.Request.Context(), `
		SELECT COALESCE(is_verified, FALSE), verified_by_admin, verified_at
		FROM payment_transactions WHERE transaction_id = $1
	`, transactionID).Scan(&dbIsVerified, &dbVerifiedByAdmin, &dbVerifiedAt)

	logMsg := fmt.Sprintf("ApprovePaymentVerification: transaction=%s user_id=%d db_user_status=%s is_verified=%v verified_by_admin=%v verified_at=%v",
		transactionID, userID, dbUserStatus, dbIsVerified, dbVerifiedByAdmin, dbVerifiedAt)
	fmt.Println(logMsg)
	_ = utils.LogApproval(logMsg)

	c.JSON(http.StatusOK, gin.H{
		"message": "Approval pembayaran berhasil dan akun siswa telah diaktifkan",
		"data": gin.H{
			"transaction_id": transactionID,
			"user_id":        userID,
			"is_verified":    dbIsVerified,
			"status":         dbUserStatus,
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

	// Auto-sync pending transactions dengan Midtrans
	autoSyncPendingTransactions(c.Request.Context())

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
