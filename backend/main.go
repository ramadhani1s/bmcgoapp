package main

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/routes"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	config.ConnectDB()

	r := gin.Default()
	if err := r.SetTrustedProxies([]string{"127.0.0.1", "::1"}); err != nil {
		log.Fatalf("failed to set trusted proxies: %v", err)
	}

	// Allow browser clients (Flutter web) to call backend APIs.
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	})

	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Backend jalan 🚀",
		})
	})

	routes.AuthRoutes(r)
	routes.ProtectedRoutes(r)
	routes.PaymentRoutes(r)
	routes.MentorRoutes(r)

	if err := r.Run(":8080"); err != nil {
		log.Fatalf("failed to start server on :8080: %v", err)
	}
}
