package handlers

import (
	"bmcgoapp-backend/config"
	"context"
	"fmt"
	"net/http"
	"net/url"
	"regexp"
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
	CustomerPhone string `json:"customer_phone" binding:"required"`
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

type ManualTransferConfirmationRequest struct {
	PackageID    string `json:"package_id" binding:"required"`
	PackageTitle string `json:"package_title" binding:"required"`
	Amount       string `json:"amount" binding:"required"`
}

type VerificationItem struct {
	TransactionID   string     `json:"transaction_id"`
	UserID          int        `json:"user_id"`
	StudentName     string     `json:"student_name"`
	ClassName       string     `json:"class_name"`
	SchoolName      string     `json:"school_name"`
	Address         string     `json:"address"`
	RegisteredWA    string     `json:"registered_whatsapp"`
	PackageID       string     `json:"package_id"`
	PackageTitle    string     `json:"package_title"`
	Amount          int64      `json:"amount"`
	Status          string     `json:"status"`
	PaymentType     string     `json:"payment_type"`
	CustomerEmail   string     `json:"customer_email"`
	CustomerPhone   string     `json:"customer_phone"`
	IsVerified      bool       `json:"is_verified"`
	VerifiedAt      *time.Time `json:"verified_at"`
	VerifiedByAdmin *int       `json:"verified_by_admin"`
	UserStatus      string     `json:"user_status"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

type VerificationOverview struct {
	Waiting  int                `json:"waiting"`
	Approved int                `json:"approved"`
	Rejected int                `json:"rejected"`
	Items    []VerificationItem `json:"items"`
}

// InitMidtrans initialize Midtrans SDK
func InitMidtrans() {
	// GANTI DENGAN SERVER KEY MIDTRANS KAMU
	midtrans.ServerKey = "Mid-server-QRDtut5gyc07B9FjYtz4-fIQ"
	midtrans.ClientKey = "Mid-client-oGUyoloFZJXYlklg"
	// Gunakan "Production" untuk production
	midtrans.SetPaymentAppendNotification("http://localhost:8080/payment/notification")
}

func normalizeStatus(status string) string {
	s := strings.ToLower(strings.TrimSpace(status))
	if s == "settlement" || s == "capture" || s == "success" {
		return "success"
	}
	if s == "pending" {
		return "pending"
	}
	if s == "deny" || s == "cancel" || s == "expire" || s == "failure" || s == "failed" {
		return "failed"
	}
	return s
}

func normalizeWhatsAppNumber(raw string) string {
	phone := strings.TrimSpace(raw)
	if phone == "" {
		return ""
	}

	nonDigits := regexp.MustCompile(`\D`)
	phone = nonDigits.ReplaceAllString(phone, "")

	if strings.HasPrefix(phone, "0") {
		phone = "62" + strings.TrimPrefix(phone, "0")
	} else if strings.HasPrefix(phone, "8") {
		phone = "62" + phone
	}

	if !strings.HasPrefix(phone, "62") {
		return ""
	}

	return phone
}

func buildVerificationWAMessage() string {
	return strings.Join([]string{
		"Pembayaran Anda telah terverifikasi dan akun Anda sudah AKTIF! ✅",
		"Selamat bergabung di Bimbel Bintang Muda Center! 🚀",
		"Mari kita raih prestasi bersama! 💪📚",
	}, "\n")
}

func buildWALink(phone, message string) string {
	normalized := normalizeWhatsAppNumber(phone)
	if normalized == "" {
		return ""
	}

	return fmt.Sprintf("https://wa.me/%s?text=%s", normalized, url.QueryEscape(message))
}

func loadVerificationItems(ctx context.Context) ([]VerificationItem, error) {
	rows, err := config.DB.Query(
		ctx,
		`SELECT
			t.transaction_id,
			t.user_id,
			COALESCE(NULLIF(s.nama_siswa, ''), NULLIF(u.nama, ''), t.customer_name),
			COALESCE(NULLIF(s.kelas, ''), ''),
			COALESCE(NULLIF(s.asal_sekolah, ''), ''),
			'' AS address,
			COALESCE(NULLIF(u.phone_number, ''), COALESCE(t.customer_phone, '')),
			t.package_id,
			t.package_title,
			t.amount,
			t.status,
			COALESCE(t.payment_type, ''),
			COALESCE(t.customer_email, ''),
			COALESCE(t.customer_phone, ''),
			COALESCE(t.is_verified, FALSE),
			t.verified_at,
			t.verified_by_admin,
			COALESCE(u.status, ''),
			t.created_at,
			t.updated_at
		FROM (
			SELECT DISTINCT ON (pt.user_id)
				pt.transaction_id,
				pt.user_id,
				pt.package_id,
				pt.package_title,
				pt.amount,
				pt.status,
				pt.payment_type,
				pt.customer_name,
				pt.customer_email,
				pt.customer_phone,
				pt.is_verified,
				pt.verified_at,
				pt.verified_by_admin,
				pt.created_at,
				pt.updated_at
			FROM payment_transactions pt
			ORDER BY pt.user_id, pt.created_at DESC
		) t
		LEFT JOIN users u ON u.id = t.user_id
		LEFT JOIN siswa s ON s.user_id = t.user_id
		ORDER BY t.created_at DESC
		LIMIT 200`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]VerificationItem, 0)
	for rows.Next() {
		item := VerificationItem{}
		if err := rows.Scan(
			&item.TransactionID,
			&item.UserID,
			&item.StudentName,
			&item.ClassName,
			&item.SchoolName,
			&item.Address,
			&item.RegisteredWA,
			&item.PackageID,
			&item.PackageTitle,
			&item.Amount,
			&item.Status,
			&item.PaymentType,
			&item.CustomerEmail,
			&item.CustomerPhone,
			&item.IsVerified,
			&item.VerifiedAt,
			&item.VerifiedByAdmin,
			&item.UserStatus,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return nil, err
		}
		item.Status = normalizeStatus(item.Status)
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

// CreateTransaction membuat transaction di Midtrans
func CreateTransaction(c *gin.Context) {
	var req PaymentRequest

	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	// Ambil user dari JWT
	userIDValue, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"message": "Unauthorized",
		})
		return
	}

	userIDInt, ok := userIDValue.(int)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{
			"message": "Unauthorized",
		})
		return
	}

	// Convert amount dari string ke integer
	amount, err := strconv.ParseInt(req.Amount, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"message": "Invalid amount format",
		})
		return
	}

	// Generate unique transaction ID to avoid Midtrans duplicate order_id errors
	transactionID := fmt.Sprintf(
		"BMC-%d-%s-%d",
		userIDInt,
		req.PackageID,
		time.Now().UnixMilli(),
	)

	// Setup Snap request
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
		Items: &[]midtrans.ItemDetails{
			{
				ID:    req.PackageID,
				Price: amount,
				Qty:   1,
				Name:  req.PackageTitle,
			},
		},
		BniVa: &snap.BniVa{},
		Callbacks: &snap.Callbacks{
			Finish: "https://yourdomain.com/payment/finish",
		},
	}

	// Create transaction
	snapResp, midtransErr := snap.CreateTransaction(snapReq)
	if midtransErr != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Failed to create transaction",
			"error":   midtransErr.Error(),
		})
		return
	}

	_, dbErr := config.DB.Exec(
		c.Request.Context(),
		`INSERT INTO payment_transactions (
			transaction_id, user_id, package_id, package_title, amount, status,
			payment_type, customer_name, customer_email, customer_phone, created_at, updated_at
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,NOW(),NOW())
		ON CONFLICT (transaction_id) DO UPDATE SET
			package_id = EXCLUDED.package_id,
			package_title = EXCLUDED.package_title,
			amount = EXCLUDED.amount,
			status = EXCLUDED.status,
			updated_at = NOW()`,
		transactionID,
		userIDInt,
		req.PackageID,
		req.PackageTitle,
		amount,
		"pending",
		"",
		req.CustomerName,
		req.CustomerEmail,
		req.CustomerPhone,
	)
	if dbErr != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Failed to save transaction",
			"error":   dbErr.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Transaction created successfully",
		"data": PaymentResponse{
			Token:         snapResp.Token,
			RedirectURL:   snapResp.RedirectURL,
			TransactionID: transactionID,
			Status:        "pending",
		},
	})
}

// CheckPaymentStatus mengecek status pembayaran
func CheckPaymentStatus(c *gin.Context) {
	transactionID := c.Param("transactionId")

	if transactionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"message": "Transaction ID is required",
		})
		return
	}

	// Get transaction status dari Midtrans
	resp, err := coreapi.CheckTransaction(transactionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Failed to check transaction status",
			"error":   err.Error(),
		})
		return
	}

	normalizedStatus := normalizeStatus(resp.TransactionStatus)
	_, _ = config.DB.Exec(
		c.Request.Context(),
		`UPDATE payment_transactions
		 SET status = $1,
		     payment_type = COALESCE(NULLIF($2, ''), payment_type),
		     updated_at = NOW()
		 WHERE transaction_id = $3`,
		normalizedStatus,
		resp.PaymentType,
		transactionID,
	)

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

// FinishTransaction menyelesaikan transaction & query status ke Midtrans
func FinishTransaction(c *gin.Context) {
	var req struct {
		TransactionID string `json:"transaction_id" binding:"required"`
	}

	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"message": "Invalid request data",
		})
		return
	}

	debugPrint := fmt.Sprintf("DEBUG FinishTransaction: querying Midtrans for %s", req.TransactionID)
	fmt.Println(debugPrint)

	// Query langsung ke Midtrans untuk tau status sebenarnya
	resp, err := coreapi.CheckTransaction(req.TransactionID)
	if err != nil {
		// Error saat query Midtrans - log error
		fmt.Printf("ERROR: Midtrans CheckTransaction failed: %v\n", err)

		// Assume pending jika error (belum ada response dari Midtrans)
		normalizedStatus := "pending"
		_, _ = config.DB.Exec(
			c.Request.Context(),
			`UPDATE payment_transactions
			 SET status = $1,
			     updated_at = NOW()
			 WHERE transaction_id = $2`,
			normalizedStatus,
			req.TransactionID,
		)
		c.JSON(http.StatusOK, gin.H{
			"message": "Transaction finished (pending verification - Midtrans error)",
			"error":   err.Error(),
			"data": gin.H{
				"transaction_id": req.TransactionID,
				"status":         normalizedStatus,
			},
		})
		return
	}

	// Success - update dengan status dari Midtrans
	fmt.Printf("DEBUG: Midtrans response: TransactionID=%s, Status=%s, PaymentType=%s\n",
		resp.TransactionID, resp.TransactionStatus, resp.PaymentType)

	// Normalize status dari Midtrans
	normalizedStatus := normalizeStatus(resp.TransactionStatus)
	fmt.Printf("DEBUG: Normalized status: %s\n", normalizedStatus)

	_, _ = config.DB.Exec(
		c.Request.Context(),
		`UPDATE payment_transactions
		 SET status = $1,
		     payment_type = COALESCE(NULLIF($2, ''), payment_type),
		     updated_at = NOW()
		 WHERE transaction_id = $3`,
		normalizedStatus,
		resp.PaymentType,
		req.TransactionID,
	)

	c.JSON(http.StatusOK, gin.H{
		"message": "Transaction finished",
		"data": gin.H{
			"transaction_id": req.TransactionID,
			"status":         normalizedStatus,
		},
	})
}

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

	// Refresh pending transactions first so history reflects the latest Midtrans status.
	pendingRows, err := config.DB.Query(
		c.Request.Context(),
		`SELECT transaction_id
		 FROM payment_transactions
		 WHERE user_id = $1 AND status = 'pending'`,
		userIDInt,
	)
	if err == nil {
		for pendingRows.Next() {
			var transactionID string
			if scanErr := pendingRows.Scan(&transactionID); scanErr != nil {
				continue
			}

			resp, checkErr := coreapi.CheckTransaction(transactionID)
			if checkErr != nil {
				fmt.Printf("WARN: refresh payment status failed for %s: %v\n", transactionID, checkErr)
				continue
			}

			normalizedStatus := normalizeStatus(resp.TransactionStatus)
			_, _ = config.DB.Exec(
				c.Request.Context(),
				`UPDATE payment_transactions
				 SET status = $1,
				     payment_type = COALESCE(NULLIF($2, ''), payment_type),
				     updated_at = NOW()
				 WHERE transaction_id = $3`,
				normalizedStatus,
				resp.PaymentType,
				transactionID,
			)
		}
		pendingRows.Close()
	}

	status := strings.ToLower(strings.TrimSpace(c.Query("status")))

	query := `SELECT transaction_id, package_id, package_title, amount, status,
		COALESCE(payment_type, ''), created_at, updated_at
		FROM payment_transactions
		WHERE user_id = $1`
	args := []interface{}{userIDInt}

	if status != "" {
		query += ` AND status = $2`
		args = append(args, status)
	}

	query += ` ORDER BY created_at DESC LIMIT 100`

	rows, err := config.DB.Query(c.Request.Context(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Failed to load payment history",
			"error":   err.Error(),
		})
		return
	}
	defer rows.Close()

	history := make([]PaymentHistoryItem, 0)
	for rows.Next() {
		item := PaymentHistoryItem{}
		if err := rows.Scan(
			&item.TransactionID,
			&item.PackageID,
			&item.PackageTitle,
			&item.Amount,
			&item.Status,
			&item.PaymentType,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"message": "Failed to parse payment history",
				"error":   err.Error(),
			})
			return
		}
		history = append(history, item)
	}

	if err := rows.Err(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Failed to read payment history",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Payment history retrieved",
		"data":    history,
	})
}

// SubmitManualTransferConfirmation siswa konfirmasi sudah transfer VA agar masuk antrian verifikasi admin.
func SubmitManualTransferConfirmation(c *gin.Context) {
	userIDValue, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	userID, ok := userIDValue.(int)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"message": "Unauthorized"})
		return
	}

	var req ManualTransferConfirmationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	amount, err := strconv.ParseInt(strings.TrimSpace(req.Amount), 10, 64)
	if err != nil || amount <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"message": "Invalid amount",
		})
		return
	}

	var customerName string
	var customerEmail string
	var customerPhone string
	err = config.DB.QueryRow(
		c.Request.Context(),
		`SELECT
			COALESCE(NULLIF(s.nama_siswa, ''), NULLIF(u.nama, ''), ''),
			COALESCE(NULLIF(u.email, ''), ''),
			COALESCE(NULLIF(u.phone_number, ''), '')
		 FROM users u
		 LEFT JOIN siswa s ON s.user_id = u.id
		 WHERE u.id = $1`,
		userID,
	).Scan(&customerName, &customerEmail, &customerPhone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Gagal mengambil data siswa",
			"error":   err.Error(),
		})
		return
	}

	transactionID := fmt.Sprintf(
		"BMC-MANUAL-%d-%s-%d",
		userID,
		strings.TrimSpace(req.PackageID),
		time.Now().UnixMilli(),
	)

	_, err = config.DB.Exec(
		c.Request.Context(),
		`INSERT INTO payment_transactions (
			transaction_id, user_id, package_id, package_title, amount, status,
			payment_type, customer_name, customer_email, customer_phone,
			is_verified, created_at, updated_at
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,FALSE,NOW(),NOW())`,
		transactionID,
		userID,
		strings.TrimSpace(req.PackageID),
		strings.TrimSpace(req.PackageTitle),
		amount,
		"success",
		"bni_transfer_manual",
		customerName,
		customerEmail,
		customerPhone,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Gagal menyimpan konfirmasi transfer",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Konfirmasi transfer diterima. Menunggu verifikasi admin.",
		"data": gin.H{
			"transaction_id": transactionID,
			"status":         "success",
			"is_verified":    false,
		},
	})
}

// VerifyPayment admin verifikasi pembayaran
func VerifyPayment(c *gin.Context) {
	transactionID := c.Param("transactionId")

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

	if strings.TrimSpace(transactionID) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Transaction ID is required"})
		return
	}

	var userID int
	var customerPhone string
	var registeredWhatsApp string
	err := config.DB.QueryRow(
		c.Request.Context(),
		`SELECT pt.user_id,
				COALESCE(pt.customer_phone, ''),
				COALESCE(NULLIF(u.phone_number, ''), '')
		 FROM payment_transactions pt
		 LEFT JOIN users u ON u.id = pt.user_id
		 WHERE pt.transaction_id = $1`,
		transactionID,
	).Scan(&userID, &customerPhone, &registeredWhatsApp)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"message": "Transaction not found",
			"error":   err.Error(),
		})
		return
	}

	verifyResult, err := config.DB.Exec(
		c.Request.Context(),
		`UPDATE payment_transactions
		 SET status = 'success',
		     is_verified = TRUE,
		     verified_at = NOW(),
		     verified_by_admin = $1,
		     updated_at = NOW()
		 WHERE transaction_id = $2
		   AND status IN ('success', 'pending')`,
		adminID,
		transactionID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Failed to verify payment",
			"error":   err.Error(),
		})
		return
	}

	if verifyResult.RowsAffected() == 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"message": "Payment tidak dalam status yang bisa diverifikasi",
		})
		return
	}

	_, err = config.DB.Exec(
		c.Request.Context(),
		`UPDATE users
		 SET status = 'aktif'
		 WHERE id = $1`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Payment verified, tetapi gagal aktivasi akun siswa",
			"error":   err.Error(),
		})
		return
	}

	waTemplate := buildVerificationWAMessage()
	waPhone := strings.TrimSpace(registeredWhatsApp)
	if waPhone == "" {
		waPhone = strings.TrimSpace(customerPhone)
	}
	waLink := buildWALink(waPhone, waTemplate)

	c.JSON(http.StatusOK, gin.H{
		"message": "Payment verified successfully",
		"data": gin.H{
			"transaction_id":       transactionID,
			"is_verified":          true,
			"user_id":              userID,
			"user_status":          "aktif",
			"whatsapp_number":      waPhone,
			"whatsapp_message":     waTemplate,
			"whatsapp_template_ok": waLink != "",
			"whatsapp_url":         waLink,
		},
	})
}

// RejectPayment admin reject pembayaran
func RejectPayment(c *gin.Context) {
	transactionID := c.Param("transactionId")

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

	// Update status ke failed saat di-reject
	var rejectedUserID int
	err := config.DB.QueryRow(
		c.Request.Context(),
		`UPDATE payment_transactions
		 SET status = 'failed',
		     is_verified = FALSE,
		     verified_at = NULL,
		     verified_by_admin = $1,
		     updated_at = NOW()
		 WHERE transaction_id = $2
		 RETURNING user_id`,
		adminID,
		transactionID,
	).Scan(&rejectedUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Failed to reject payment",
			"error":   err.Error(),
		})
		return
	}

	var stillActive bool
	err = config.DB.QueryRow(
		c.Request.Context(),
		`SELECT EXISTS(
			SELECT 1
			FROM payment_transactions
			WHERE user_id = $1 AND status = 'success' AND is_verified = TRUE
		)`,
		rejectedUserID,
	).Scan(&stillActive)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Payment rejected but failed checking user status",
			"error":   err.Error(),
		})
		return
	}

	newStatus := "nonaktif"
	if stillActive {
		newStatus = "aktif"
	}

	_, err = config.DB.Exec(
		c.Request.Context(),
		`UPDATE users SET status = $1 WHERE id = $2`,
		newStatus,
		rejectedUserID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Payment rejected but failed to update user status",
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Payment rejected",
		"data": gin.H{
			"transaction_id": transactionID,
			"is_verified":    false,
		},
	})
}

// GetVerificationOverview admin ambil ringkasan dan daftar verifikasi
func GetVerificationOverview(c *gin.Context) {
	overview := VerificationOverview{}
	items, err := loadVerificationItems(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Failed to load verification items",
			"error":   err.Error(),
		})
		return
	}

	for _, item := range items {
		if item.IsVerified {
			overview.Approved++
			continue
		}

		if item.Status == "failed" {
			overview.Rejected++
			continue
		}

		if item.Status == "success" || item.Status == "pending" {
			overview.Waiting++
		}
	}

	overview.Items = items

	c.JSON(http.StatusOK, gin.H{
		"message": "Verification overview retrieved",
		"data":    overview,
	})
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

	var isVerified bool
	var verifiedAt *time.Time

	err := config.DB.QueryRow(
		c.Request.Context(),
		`SELECT COALESCE(is_verified, FALSE), verified_at
		 FROM payment_transactions
		 WHERE user_id = $1 AND status = 'success'
		 ORDER BY created_at DESC
		 LIMIT 1`,
		userIDInt,
	).Scan(&isVerified, &verifiedAt)

	if err != nil {
		// Belum ada pembayaran atau belum success
		c.JSON(http.StatusOK, gin.H{
			"message":     "Payment verification status",
			"is_verified": false,
			"verified_at": nil,
			"can_access":  false,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":     "Payment verification status",
		"is_verified": isVerified,
		"verified_at": verifiedAt,
		"can_access":  isVerified,
	})
}

// GetPendingVerifications admin ambil list pembayaran yg pending verifikasi
func GetPendingVerifications(c *gin.Context) {
	items, err := loadVerificationItems(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Failed to load pending verifications",
			"error":   err.Error(),
		})
		return
	}

	pendingItems := make([]VerificationItem, 0)
	for _, item := range items {
		if (item.Status == "success" || item.Status == "pending") && !item.IsVerified {
			pendingItems = append(pendingItems, item)
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Pending verifications retrieved",
		"data":    pendingItems,
	})
}

// PaymentNotification menerima notifikasi dari Midtrans
func PaymentNotification(c *gin.Context) {
	var notification map[string]interface{}

	if err := c.BindJSON(&notification); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"message": "Invalid notification data",
		})
		return
	}

	// Ambil transaction ID dan status kalau tersedia
	transactionID, _ := notification["order_id"].(string)
	transactionStatus, _ := notification["transaction_status"].(string)
	paymentType, _ := notification["payment_type"].(string)
	normalizedStatus := normalizeStatus(transactionStatus)

	if transactionID != "" {
		_, _ = config.DB.Exec(
			c.Request.Context(),
			`UPDATE payment_transactions
			 SET status = $1,
			     payment_type = COALESCE(NULLIF($2, ''), payment_type),
			     updated_at = NOW()
			 WHERE transaction_id = $3`,
			normalizedStatus,
			paymentType,
			transactionID,
		)
	}

	c.JSON(http.StatusOK, gin.H{
		"message":            "Notification received",
		"order_id":           transactionID,
		"transaction_status": transactionStatus,
		"normalized_status":  normalizedStatus,
		"payment_type":       paymentType,
	})
}
