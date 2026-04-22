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
			payment.GET("/status/:transactionId", handlers.CheckPaymentStatus)
			payment.POST("/finish-transaction", handlers.FinishTransaction)
		}
	}
}
