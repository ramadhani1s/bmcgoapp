package routes

import (
	"bmcgoapp-backend/handlers"
	"bmcgoapp-backend/middleware"

	"github.com/gin-gonic/gin"
)

func AuthRoutes(r *gin.Engine) {
	r.POST("/save-fcm-token", handlers.SaveFCMToken)
	// register under /auth
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

	// also register same routes under /api/auth to support frontend API prefix
	apiAuth := r.Group("/api/auth")
	{
		apiAuth.POST("/register", handlers.RegisterHandler)
		apiAuth.POST("/login", handlers.LoginHandler)
	}

	apiAdminAuth := r.Group("/api/auth")
	apiAdminAuth.Use(middleware.AuthMiddleware(), middleware.RoleMiddleware(1))
	{
		apiAdminAuth.POST("/create-mentor", handlers.CreateMentor)
		apiAdminAuth.GET("/mentors", handlers.GetMentors)
		apiAdminAuth.DELETE("/mentors/:id", handlers.DeleteMentor)
	}
}
