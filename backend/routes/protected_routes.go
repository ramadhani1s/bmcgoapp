package routes

import (
	"bmcgoapp-backend/handlers"
	"bmcgoapp-backend/middleware"

	"github.com/gin-gonic/gin"
)

func ProtectedRoutes(r *gin.Engine) {

	// group yang butuh login
	auth := r.Group("/api")
	auth.Use(middleware.AuthMiddleware())

	// ================= SEMUA USER =================
	auth.GET("/profile", func(c *gin.Context) {
		userID, _ := c.Get("user_id")

		c.JSON(200, gin.H{
			"message": "Profile berhasil diakses",
			"user_id": userID,
		})
	})

	// ================= ADMIN ONLY =================
	admin := auth.Group("/admin")
	admin.Use(middleware.RoleMiddleware(1)) // 1 = admin

	admin.GET("/dashboard", handlers.GetAdminDashboard)
	admin.GET("/dashboard-summary", handlers.GetAdminDashboardSummary)

	// ================= MENTOR ONLY =================
	mentor := auth.Group("/mentor")
	mentor.Use(middleware.RoleMiddleware(2)) // 2 = mentor

	mentor.GET("/kelas", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Mentor kelas",
		})
	})

	// ================= SISWA ONLY =================
	siswa := auth.Group("/siswa")
	siswa.Use(middleware.RoleMiddleware(3)) // 3 = siswa

	siswa.GET("/jadwal", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Jadwal siswa",
		})
	})
}
