package routes

import (
	"bmcgoapp-backend/handlers"
	"bmcgoapp-backend/middleware"

	"github.com/gin-gonic/gin"
)

func ProtectedRoutes(r *gin.Engine) {

	// ================= PUBLIC ROUTES (NO AUTH) =================
	// Public paket les endpoint untuk client/mobile
	r.GET("/api/paket-les", handlers.GetPaketLesList)
	r.GET("/api/paket-les/:id", handlers.GetPaketLesDetail)

	// Public pengumuman endpoint
	r.GET("/api/pengumuman", handlers.GetPengumumanList)
	r.GET("/api/pengumuman/:id", handlers.GetPengumumanDetail)

	// Public jadwal pembelajaran endpoint untuk siswa
	r.GET("/api/jadwal", handlers.GetJadwalList)
	r.GET("/api/jadwal/:id", handlers.GetJadwalDetail)
	r.GET("/api/jadwal-by-hari", handlers.GetJadwalByHari)

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

	// Paket Les Routes
	admin.POST("/paket-les", handlers.CreatePaketLes)
	admin.GET("/paket-les", handlers.GetPaketLesList)
	admin.GET("/paket-les/:id", handlers.GetPaketLesDetail)
	admin.PUT("/paket-les/:id", handlers.UpdatePaketLes)
	admin.DELETE("/paket-les/:id", handlers.DeletePaketLes)
	admin.GET("/paket-les-stats", handlers.GetPaketLesStats)

	// Jadwal Pembelajaran Routes
	admin.POST("/jadwal", handlers.CreateJadwal)
	admin.GET("/jadwal", handlers.GetJadwalList)
	admin.GET("/jadwal/:id", handlers.GetJadwalDetail)
	admin.PUT("/jadwal/:id", handlers.UpdateJadwal)
	admin.DELETE("/jadwal/:id", handlers.DeleteJadwal)

	// Pengumuman Routes (admin)
	admin.POST("/pengumuman", handlers.CreatePengumuman)
	admin.GET("/pengumuman", handlers.AdminGetPengumumanList)
	admin.GET("/pengumuman/:id", handlers.GetPengumumanDetail)
	admin.PUT("/pengumuman/:id", handlers.UpdatePengumuman)
	admin.DELETE("/pengumuman/:id", handlers.DeletePengumuman)

	// Admin mapping Routes
	admin.GET("/mappings", handlers.GetAdminMappings)
	admin.GET("/mappings/users", handlers.GetUsersForMapping)
	admin.POST("/mappings/sync", handlers.SyncAdminMappings)
	admin.PUT("/mappings/:adminId", handlers.UpdateAdminMapping)

	// Alumni Routes
	admin.GET("/alumni", handlers.GetAlumniHandler)
	admin.GET("/alumni/:id", handlers.GetAlumniByIdHandler)
	admin.POST("/alumni", handlers.CreateAlumniHandler)
	admin.PUT("/alumni/:id", handlers.UpdateAlumniHandler)
	admin.DELETE("/alumni/:id", handlers.DeleteAlumniHandler)

	// Upload route for admin (image uploads)
	admin.POST("/upload", handlers.UploadFileHandler)

	// ================= MENTOR ONLY =================
	mentor := auth.Group("/mentor")
	mentor.Use(middleware.RoleMiddleware(2)) // 2 = mentor

	mentor.GET("/kelas", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Mentor kelas",
		})
	})

	mentor.GET("/soal-latihan", handlers.GetSoalLatihanHandler)
	mentor.POST("/soal-latihan", handlers.CreateSoalLatihanHandler)
	mentor.PUT("/soal-latihan/:soalId", handlers.UpdateSoalLatihanHandler)
	mentor.DELETE("/soal-latihan/:soalId", handlers.DeleteSoalLatihanHandler)

	mentor.GET("/tryout-soal", handlers.GetTryoutSoalHandler)
	mentor.POST("/tryout-soal", handlers.CreateTryoutSoalHandler)
	mentor.PUT("/tryout-soal/:id", handlers.UpdateTryoutSoalHandler)
	mentor.DELETE("/tryout-soal/:id", handlers.DeleteTryoutSoalHandler)

	mentor.GET("/olimpiade-soal", handlers.GetOlimpiadseSoalHandler)
	mentor.POST("/olimpiade-soal", handlers.CreateOlimpiadseSoalHandler)
	mentor.PUT("/olimpiade-soal/:id", handlers.UpdateOlimpiadseSoalHandler)
	mentor.DELETE("/olimpiade-soal/:id", handlers.DeleteOlimpiadseSoalHandler)

	mentor.GET("/tryout", handlers.GetTryoutHandler)
	mentor.POST("/tryout", handlers.CreateTryoutHandler)
	mentor.PUT("/tryout/:id", handlers.UpdateTryoutHandler)
	mentor.DELETE("/tryout/:id", handlers.DeleteTryoutHandler)
	mentor.GET("/tryout/:id/hasil", handlers.GetHasilTryoutByTryoutHandler)
	mentor.POST("/tryout/:id/hasil", handlers.CreateHasilTryoutHandler)

	mentor.GET("/evaluasi", handlers.GetEvaluasiHandler)
	mentor.POST("/evaluasi", handlers.CreateEvaluasiHandler)

	mentor.GET("/olimpiade", handlers.GetOlimpiadeHandler)
	mentor.POST("/olimpiade", handlers.CreateOlimpiadeHandler)
	mentor.PUT("/olimpiade/:id", handlers.UpdateOlimpiadeHandler)
	mentor.DELETE("/olimpiade/:id", handlers.DeleteOlimpiadeHandler)
	mentor.GET("/olimpiade/:id/peserta", handlers.GetPesertaOlimpiadeHandler)
	mentor.POST("/olimpiade/:id/peserta", handlers.CreatePesertaOlimpiadeHandler)
	mentor.GET("/jadwal", handlers.GetMentorJadwalList)
	mentor.POST("/attendance/start", handlers.StartAttendanceSessionHandler)
	mentor.GET("/attendance/active", handlers.GetActiveAttendanceSessionHandler)
	mentor.GET("/attendance/sessions/:sessionId/summary", handlers.GetAttendanceSessionSummaryHandler)
	mentor.GET("/attendance/rules", handlers.DebugAttendanceExplainHandler)

	// ================= SISWA ONLY =================
	siswa := auth.Group("/siswa")
	siswa.Use(middleware.RoleMiddleware(3)) // 3 = siswa

	siswa.GET("/jadwal", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Jadwal siswa",
		})
	})

	siswa.POST("/attendance/submit", handlers.SubmitAttendanceTokenHandler)
	siswa.GET("/attendance/active", handlers.GetActiveAttendanceSessionForSiswaHandler)
	siswa.GET("/attendance/history", handlers.GetStudentAttendanceHistoryHandler)
	siswa.GET("/materi", handlers.GetAllMateri)
	siswa.GET("/soal-latihan", handlers.GetSoalLatihanSiswa)
	siswa.GET("/pengumuman", handlers.GetPengumuman)
	siswa.GET("/olimpiade", handlers.GetOlimpiadeSiswa)
	siswa.GET("/olimpiade/:id/soal", handlers.GetSoalOlimpiade)
	siswa.POST("/olimpiade/:id/submit", handlers.SubmitOlimpiade)

}