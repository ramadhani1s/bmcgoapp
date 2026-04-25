package routes

import (
	"bmcgoapp-backend/handlers"
	"bmcgoapp-backend/middleware"

	"github.com/gin-gonic/gin"
)

func AuthRoutes(r *gin.Engine) {
	auth := r.Group("/auth")
	{
		auth.POST("/register", handlers.RegisterHandler)
		auth.POST("/login", handlers.LoginHandler)
	}

	adminAuth := r.Group("/auth")
	adminAuth.Use(middleware.AuthMiddleware(), middleware.RoleMiddleware(1))
	{
		adminAuth.POST("/create-mentor", handlers.CreateMentor)
		adminAuth.GET("/mentors", handlers.GetMentors)
		adminAuth.DELETE("/mentors/:id", handlers.DeleteMentor)
	}
}