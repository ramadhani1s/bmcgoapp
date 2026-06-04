package handlers

import (
	"context"
	"net/http"
	"strings"

	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
	"bmcgoapp-backend/services"
	"bmcgoapp-backend/utils"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
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

	// Normalisasi input supaya payload dari frontend yang berbeda tetap terbaca
	if user.Nama == "" {
		user.Nama = c.PostForm("nama")
	}
	if user.WhatsApp == "" {
		user.WhatsApp = c.PostForm("whatsapp")
	}
	if user.Alamat == "" {
		user.Alamat = c.PostForm("alamat")
	}

	user.Nama = strings.TrimSpace(user.Nama)
	user.Email = strings.TrimSpace(user.Email)
	user.Password = strings.TrimSpace(user.Password)
	user.Kelas = strings.TrimSpace(user.Kelas)
	user.AsalSekolah = strings.TrimSpace(user.AsalSekolah)
	user.WhatsApp = strings.TrimSpace(user.WhatsApp)
	user.Alamat = strings.TrimSpace(user.Alamat)

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

	input.Email = strings.TrimSpace(input.Email)
	input.Password = strings.TrimSpace(input.Password)

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

// ================= UPDATE PROFILE =================
func UpdateProfileHandler(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User tidak terautentikasi"})
		return
	}

	var req struct {
		Nama        string `json:"nama"`
		Email       string `json:"email"`
		OldPassword string `json:"old_password"`
		NewPassword string `json:"new_password"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format request tidak valid"})
		return
	}

	req.Nama = strings.TrimSpace(req.Nama)
	req.Email = strings.TrimSpace(req.Email)
	req.OldPassword = strings.TrimSpace(req.OldPassword)
	req.NewPassword = strings.TrimSpace(req.NewPassword)

	if req.Nama == "" || req.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Nama dan email wajib diisi"})
		return
	}

	// 1. Cek apakah user ada di DB.
	// Khususnya untuk default admin (userID = 1) yang mungkin belum ada barisnya di tabel 'users'.
	var count int
	err := config.DB.QueryRow(context.Background(), `SELECT COUNT(*) FROM users WHERE id = $1`, userID).Scan(&count)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal memeriksa status user", "details": err.Error()})
		return
	}

	// Jika user tidak ada di database (misal default admin ID=1), kita buatkan row-nya terlebih dahulu
	if count == 0 {
		// Dapatkan role_id dari token context
		roleID, _ := c.Get("role_id")
		// default password hash if not changing password is a dummy or BMC123 hashed
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte("BMC123"), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal inisialisasi default password"})
			return
		}

		// Insert user baru dengan ID yang sesuai
		_, err = config.DB.Exec(context.Background(), `
			INSERT INTO users (id, nama, email, password, role_id, status)
			VALUES ($1, $2, $3, $4, $5, 'aktif')
		`, userID, req.Nama, req.Email, string(hashedPassword), roleID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mendaftarkan user di database", "details": err.Error()})
			return
		}
	}

	// 2. Cek email unik (pastikan tidak duplikat dengan user lain)
	var duplicateID int
	err = config.DB.QueryRow(context.Background(), `
		SELECT id FROM users WHERE LOWER(email) = LOWER($1) AND id != $2 LIMIT 1
	`, req.Email, userID).Scan(&duplicateID)
	if err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email sudah digunakan oleh user lain"})
		return
	}

	// 3. Proses ganti password jika password baru diisi
	var newPasswordHashed string
	if req.NewPassword != "" {
		if req.OldPassword == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Password lama wajib diisi untuk mengubah password"})
			return
		}

		// Ambil password saat ini dari DB
		var currentPassword string
		err = config.DB.QueryRow(context.Background(), `SELECT password FROM users WHERE id = $1`, userID).Scan(&currentPassword)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil password saat ini"})
			return
		}

		// Verifikasi password lama
		err = bcrypt.CompareHashAndPassword([]byte(currentPassword), []byte(req.OldPassword))
		// toleransi plain text match untuk data lama
		if err != nil && currentPassword != req.OldPassword {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Password lama tidak sesuai"})
			return
		}

		// Hash password baru
		hashed, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal memproses password baru"})
			return
		}
		newPasswordHashed = string(hashed)
	}

	// 4. Lakukan update data
	if newPasswordHashed != "" {
		_, err = config.DB.Exec(context.Background(), `
			UPDATE users SET nama = $1, email = $2, password = $3 WHERE id = $4
		`, req.Nama, req.Email, newPasswordHashed, userID)
	} else {
		_, err = config.DB.Exec(context.Background(), `
			UPDATE users SET nama = $1, email = $2 WHERE id = $3
		`, req.Nama, req.Email, userID)
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal memperbarui profil", "details": err.Error()})
		return
	}

	// Ambil data user terupdate untuk dikembalikan
	var updatedUser models.User
	err = config.DB.QueryRow(context.Background(), `
		SELECT id, nama, email, COALESCE(role_id, 0), COALESCE(phone_number, ''), COALESCE(status, '')
		FROM users WHERE id = $1
	`, userID).Scan(
		&updatedUser.ID,
		&updatedUser.Nama,
		&updatedUser.Email,
		&updatedUser.RoleID,
		&updatedUser.PhoneNumber,
		&updatedUser.Status,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal memuat profil terupdate"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Profil berhasil diperbarui",
		"user":    updatedUser,
	})
}

