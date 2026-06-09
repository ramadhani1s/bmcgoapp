package handlers

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
	"context"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
)

func resolveAdminID(userID int) (int, error) {
	ctx := context.Background()
	var adminID int

	err := config.DB.QueryRow(ctx, `SELECT id FROM admin WHERE id = $1 LIMIT 1`, userID).Scan(&adminID)
	if err == nil {
		return adminID, nil
	}

	var userEmail string
	_ = config.DB.QueryRow(ctx, `SELECT email FROM users WHERE id = $1 LIMIT 1`, userID).Scan(&userEmail)
	if userEmail != "" {
		err = config.DB.QueryRow(ctx, `SELECT id FROM admin WHERE email = $1 LIMIT 1`, userEmail).Scan(&adminID)
		if err == nil {
			return adminID, nil
		}
	}

	var hasUserIDColumn bool
	err = config.DB.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1
			FROM information_schema.columns
			WHERE table_name = 'admin' AND column_name = 'user_id'
		)
	`).Scan(&hasUserIDColumn)
	if err == nil && hasUserIDColumn {
		err = config.DB.QueryRow(ctx, `SELECT id FROM admin WHERE user_id = $1 LIMIT 1`, userID).Scan(&adminID)
		if err == nil {
			return adminID, nil
		}
	}

	err = config.DB.QueryRow(ctx, `SELECT id FROM admin ORDER BY id ASC LIMIT 1`).Scan(&adminID)
	if err == nil {
		return adminID, nil
	}

	var userNama, userEmail2 string
	_ = config.DB.QueryRow(ctx, `SELECT nama, email FROM users WHERE id = $1 LIMIT 1`, userID).Scan(&userNama, &userEmail2)

	var hasUserIDCol, hasEmailCol, hasNamaCol bool
	_ = config.DB.QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='admin' AND column_name='user_id')
	`).Scan(&hasUserIDCol)
	_ = config.DB.QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='admin' AND column_name='email')
	`).Scan(&hasEmailCol)
	_ = config.DB.QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='admin' AND column_name='nama')
	`).Scan(&hasNamaCol)

	cols := []string{}
	vals := []interface{}{}
	if hasUserIDCol {
		cols = append(cols, "user_id")
		vals = append(vals, userID)
	}
	if hasEmailCol && userEmail2 != "" {
		cols = append(cols, "email")
		vals = append(vals, userEmail2)
	}
	if hasNamaCol && userNama != "" {
		cols = append(cols, "nama")
		vals = append(vals, userNama)
	}

	if len(cols) > 0 {
		placeholders := []string{}
		for i := range vals {
			placeholders = append(placeholders, "$"+strconv.Itoa(i+1))
		}
		q := "INSERT INTO admin (" + strings.Join(cols, ",") + ") VALUES (" + strings.Join(placeholders, ",") + ") RETURNING id"
		err = config.DB.QueryRow(ctx, q, vals...).Scan(&adminID)
		if err == nil {
			return adminID, nil
		}
	}

	return 0, fmt.Errorf("admin id tidak ditemukan untuk user_id=%d", userID)
}

// ================= SISWA =================

// GetPengumuman - siswa lihat semua pengumuman
func GetPengumuman(c *gin.Context) {
	rows, err := config.DB.Query(context.Background(), `
		SELECT id, admin_id, judul, isi, created_at
		FROM pengumuman
		ORDER BY created_at DESC
	`)
	if err != nil {
		log.Printf("[GetPengumuman] DB error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal mengambil pengumuman",
			"detail":  err.Error(),
		})
		return
	}
	defer rows.Close()

	var list []models.Pengumuman
	for rows.Next() {
		var p models.Pengumuman
		if err := rows.Scan(&p.ID, &p.AdminID, &p.Judul, &p.Isi, &p.CreatedAt); err != nil {
			log.Printf("[GetPengumuman] Scan error: %v", err)
			continue
		}
		list = append(list, p)
	}

	if list == nil {
		list = []models.Pengumuman{}
	}

	log.Printf("[GetPengumuman] Returning %d pengumuman", len(list))

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "OK",
		"data":    list,
	})
}

// ================= PUBLIC =================

// GetPengumumanList - public list semua pengumuman
func GetPengumumanList(c *gin.Context) {
	search := c.Query("search")

	query := `SELECT id, admin_id, judul, isi, created_at FROM pengumuman WHERE 1=1`
	args := []interface{}{}
	argIndex := 1

	if search != "" {
		query += ` AND (judul ILIKE $` + strconv.Itoa(argIndex) + ` OR isi ILIKE $` + strconv.Itoa(argIndex) + `)`
		args = append(args, "%"+search+"%")
		argIndex++
	}

	query += ` ORDER BY created_at DESC`

	rows, err := config.DB.Query(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal mengambil pengumuman", "detail": err.Error()})
		return
	}
	defer rows.Close()

	var list []models.Pengumuman
	for rows.Next() {
		var p models.Pengumuman
		err := rows.Scan(&p.ID, &p.AdminID, &p.Judul, &p.Isi, &p.CreatedAt)
		if err != nil {
			continue
		}
		list = append(list, p)
	}

	if list == nil {
		list = []models.Pengumuman{}
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Daftar pengumuman berhasil diambil", "data": list, "count": len(list)})
}

// GetPengumumanDetail - public detail per id
func GetPengumumanDetail(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID tidak valid"})
		return
	}

	var p models.Pengumuman
	err = config.DB.QueryRow(context.Background(), `
		SELECT id, admin_id, judul, isi, created_at
		FROM pengumuman WHERE id = $1
	`, id).Scan(&p.ID, &p.AdminID, &p.Judul, &p.Isi, &p.CreatedAt)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Pengumuman tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Detail pengumuman berhasil diambil", "data": p})
}

// ================= ADMIN =================

// CreatePengumuman - admin buat pengumuman
func CreatePengumuman(c *gin.Context) {
	var req models.CreatePengumumanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Invalid request", "detail": err.Error()})
		return
	}

	adminID := 0
	if v, ok := c.Get("user_id"); ok {
		switch vv := v.(type) {
		case int:
			adminID = vv
		case int64:
			adminID = int(vv)
		case float64:
			adminID = int(vv)
		}
	}

	if adminID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "Admin ID tidak ditemukan"})
		return
	}

	resolvedAdminID, err := resolveAdminID(adminID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Data admin tidak valid", "detail": err.Error()})
		return
	}

	var newID int
	err = config.DB.QueryRow(context.Background(), `
		INSERT INTO pengumuman (admin_id, judul, isi)
		VALUES ($1, $2, $3)
		RETURNING id
	`, resolvedAdminID, req.Judul, req.Isi).Scan(&newID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal membuat pengumuman", "detail": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"status": "success", "message": "Pengumuman berhasil dibuat", "data": gin.H{"id": newID}})
}

// AdminGetPengumumanList - admin lihat semua pengumuman
func AdminGetPengumumanList(c *gin.Context) {
	query := `SELECT id, admin_id, judul, isi, created_at FROM pengumuman ORDER BY created_at DESC`
	rows, err := config.DB.Query(context.Background(), query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal mengambil pengumuman", "detail": err.Error()})
		return
	}
	defer rows.Close()

	var list []models.Pengumuman
	for rows.Next() {
		var p models.Pengumuman
		err := rows.Scan(&p.ID, &p.AdminID, &p.Judul, &p.Isi, &p.CreatedAt)
		if err != nil {
			continue
		}
		list = append(list, p)
	}

	if list == nil {
		list = []models.Pengumuman{}
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Daftar pengumuman berhasil diambil", "data": list, "count": len(list)})
}

// UpdatePengumuman - admin edit pengumuman
func UpdatePengumuman(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID tidak valid"})
		return
	}

	var req models.UpdatePengumumanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Request tidak valid", "detail": err.Error()})
		return
	}

	_, err = config.DB.Exec(context.Background(), `
		UPDATE pengumuman SET
			judul = COALESCE(NULLIF($1, ''), judul),
			isi = COALESCE(NULLIF($2, ''), isi)
		WHERE id = $3
	`, req.Judul, req.Isi, id)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal memperbarui pengumuman", "detail": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Pengumuman berhasil diperbarui", "data": gin.H{"id": id}})
}

// DeletePengumuman - admin hapus pengumuman
func DeletePengumuman(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "ID tidak valid"})
		return
	}

	_, err = config.DB.Exec(context.Background(), `DELETE FROM pengumuman WHERE id = $1`, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal menghapus pengumuman", "detail": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Pengumuman berhasil dihapus", "data": gin.H{"id": id}})
}