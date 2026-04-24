package routes

import (
	"bmcgoapp-backend/handlers"
	"bmcgoapp-backend/middleware"

	"github.com/gin-gonic/gin"
)

func PaymentRoutes(r *gin.Engine) {
	// Inisialisasi Midtrans
	handlers.InitMidtrans()

	payment := r.Group("/payment")
	{
		// Public routes (notification dari Midtrans)
		payment.POST("/notification", handlers.PaymentNotification)

		// Protected routes (perlu authentication)
		payment.Use(middleware.AuthMiddleware())
		{
			payment.POST("/create-transaction", handlers.CreateTransaction)
			payment.POST("/submit-transfer", handlers.SubmitManualTransferConfirmation)
			payment.GET("/history", handlers.GetPaymentHistory)
			payment.GET("/status/:transactionId", handlers.CheckPaymentStatus)
			payment.POST("/finish-transaction", handlers.FinishTransaction)
			payment.GET("/verification-status", handlers.GetVerificationStatus)
		}
	}

	// Admin payment verification routes
	admin := r.Group("/admin/payment")
	admin.Use(middleware.AuthMiddleware(), middleware.RoleMiddleware(1))
	{
		admin.GET("/overview", handlers.GetVerificationOverview)
		admin.GET("/pending-verifications", handlers.GetPendingVerifications)
		admin.POST("/verify/:transactionId", handlers.VerifyPayment)
		admin.POST("/reject/:transactionId", handlers.RejectPayment)
	}
}
