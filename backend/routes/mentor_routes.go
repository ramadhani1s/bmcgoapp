package routes

import (
	"bmcgoapp-backend/handlers"

	"github.com/gin-gonic/gin"
)

func MentorRoutes(r *gin.Engine) {
	mentor := r.Group("/mentor")
	{
		mentor.GET("/", handlers.GetMentors)
		mentor.POST("/", handlers.CreateMentor)
		mentor.PUT("/:id", handlers.UpdateMentor)
		mentor.DELETE("/:id", handlers.DeleteMentor)
	}
}