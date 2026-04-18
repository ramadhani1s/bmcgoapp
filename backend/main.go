package main

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/routes"

	"github.com/gin-gonic/gin"
)

func main() {
	config.ConnectDB()

	r := gin.Default()

	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Backend jalan 🚀",
		})
	})

	routes.AuthRoutes(r)
	routes.ProtectedRoutes(r)

	r.Run(":8080")
}
