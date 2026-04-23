package main

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/routes"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	config.ConnectDB()

	r := gin.Default()

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

	r.Run(":8080")
}
