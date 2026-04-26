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

		// Materi Pembelajaran Routes
		mentor.POST("/materi", handlers.UploadMateri)
		mentor.GET("/materi", handlers.GetMateriByMentor)
		mentor.DELETE("/materi/:id", handlers.DeleteMateri)
	}
}