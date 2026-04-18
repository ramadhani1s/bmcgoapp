package handlers

import (
	"net/http"

	"bmcgoapp-backend/models"
	"bmcgoapp-backend/services"
	"bmcgoapp-backend/utils"

	"github.com/gin-gonic/gin"
)

// ================= REGISTER =================
func RegisterHandler(c *gin.Context) {
	var user models.User

	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Format request tidak valid",
			"details": err.Error(),
		})
		return
	}

	if user.Nama == "" || user.Email == "" || user.Password == "" || user.Kelas == "" || user.AsalSekolah == "" || user.WhatsApp == "" || user.Alamat == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Semua field wajib diisi",
		})
		return
	}

	if user.RoleID == 0 {
		user.RoleID = 3 // default role siswa
	}

	err := services.Register(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Gagal register",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Register berhasil",
	})
}

// ================= LOGIN =================
func LoginHandler(c *gin.Context) {
	var input models.User

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	if input.Email == "" || input.Password == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Email dan password wajib diisi",
		})
		return
	}

	user, err := services.Login(input.Email, input.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": err.Error(),
		})
		return
	}

	// 🔐 Generate JWT
	token, err := utils.GenerateToken(user.ID, user.RoleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Gagal generate token",
		})
		return
	}

	// jangan kirim password ke client
	user.Password = ""

	c.JSON(http.StatusOK, gin.H{
		"message": "Login berhasil",
		"token":   token,
		"user":    user,
	})
}
