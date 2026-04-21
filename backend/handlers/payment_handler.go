package handlers

import (
	"fmt"
	"net/http"
	"strconv"
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

// InitMidtrans initialize Midtrans SDK
func InitMidtrans() {
	// GANTI DENGAN SERVER KEY MIDTRANS KAMU
	midtrans.ServerKey = "Mid-server-QRDtut5gyc07B9FjYtz4-fIQ"
	midtrans.ClientKey = "Mid-client-oGUyoloFZJXYlklg"
	// Gunakan "Production" untuk production
	midtrans.SetPaymentAppendNotification("http://localhost:8080/payment/notification")
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
		c.JSON(http.StatusBadRequest, gin.H{
			"message": "Invalid request data",
		})
		return
	}

	// TODO: Update transaction status di database
	// Simpan transaction_id dan status untuk record

	c.JSON(http.StatusOK, gin.H{
		"message": "Transaction finished",
		"data": gin.H{
			"transaction_id": req.TransactionID,
			"status":         req.Status,
		},
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

	// TODO: Update status di database berdasarkan transaction status
	// Jika settlement atau capture: paket bisa diakses
	// Jika pending: tunggu konfirmasi
	// Jika deny atau cancel: pembayaran gagal

	c.JSON(http.StatusOK, gin.H{
		"message":            "Notification received",
		"order_id":           transactionID,
		"transaction_status": transactionStatus,
	})
}
