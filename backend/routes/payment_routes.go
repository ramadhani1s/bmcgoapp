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
		// Public routes
		payment.POST("/notification", handlers.PaymentNotification)
		payment.GET("/success", handlers.PaymentSuccessPage)

		// Protected routes (perlu authentication)
		payment.Use(middleware.AuthMiddleware())
		{
			payment.POST("/create-transaction", handlers.CreateTransaction)
			payment.GET("/history", handlers.GetPaymentHistory)
			payment.GET("/status/:transactionId", handlers.CheckPaymentStatus)
			payment.POST("/finish-transaction", handlers.FinishTransaction)
			payment.GET("/verification-status", handlers.GetVerificationStatus)
		}
	}

	// Admin payment verification routes
	admin := r.Group("/admin/payment")
	admin.Use(middleware.AuthMiddleware())
	admin.Use(middleware.RoleMiddleware(1)) // 1 = Admin role
	{
		admin.GET("/pending-verifications", handlers.GetPendingPaymentVerifications)
		admin.POST("/:transactionId/approve", handlers.ApprovePaymentVerification)
		admin.POST("/:transactionId/reject", handlers.RejectPaymentVerification)
	}

	// API prefixes for Flutter Web/App compatibility
	apiPayment := r.Group("/api/payment")
	{
		apiPayment.POST("/notification", handlers.PaymentNotification)
		apiPayment.GET("/success", handlers.PaymentSuccessPage)
		apiPayment.Use(middleware.AuthMiddleware())
		{
			apiPayment.POST("/create-transaction", handlers.CreateTransaction)
			apiPayment.GET("/history", handlers.GetPaymentHistory)
			apiPayment.GET("/status/:transactionId", handlers.CheckPaymentStatus)
			apiPayment.POST("/finish-transaction", handlers.FinishTransaction)
			apiPayment.GET("/verification-status", handlers.GetVerificationStatus)
		}
	}

	apiAdmin := r.Group("/api/admin/payment")
	apiAdmin.Use(middleware.AuthMiddleware(), middleware.RoleMiddleware(1))
	{
		apiAdmin.GET("/pending-verifications", handlers.GetPendingPaymentVerifications)
		apiAdmin.POST("/:transactionId/approve", handlers.ApprovePaymentVerification)
		apiAdmin.POST("/:transactionId/reject", handlers.RejectPaymentVerification)
	}
}
