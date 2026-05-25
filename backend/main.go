package main

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/routes"
	"bmcgoapp-backend/services"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	config.ConnectDB()
	config.InitFirebase()

	r := gin.Default()
	if err := r.SetTrustedProxies([]string{"127.0.0.1", "::1"}); err != nil {
		log.Fatalf("failed to set trusted proxies: %v", err)
	}

	// Allow browser clients (Flutter web) to call backend APIs.
	r.Use(func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		if origin != "" {
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
		} else {
			c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		}
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

	// Serve static files for uploaded materials
	r.Static("/uploads", "./uploads")

	routes.AuthRoutes(r)
	routes.ProtectedRoutes(r)
	routes.PaymentRoutes(r)
	routes.MentorRoutes(r)

	services.StartDailyNotification()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	if err := r.Run(":" + port); err != nil {
		log.Fatalf("failed to start server on :%s: %v", port, err)
	}
}
