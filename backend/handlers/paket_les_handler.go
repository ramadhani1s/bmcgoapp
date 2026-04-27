package handlers

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// parseDate - Parse date string in YYYY-MM-DD format to *time.Time
func parseDate(dateStr *string) *time.Time {
	if dateStr == nil || *dateStr == "" {
		return nil
	}
	t, err := time.Parse("2006-01-02", *dateStr)
	if err != nil {
		return nil
	}
	return &t
}

// CreatePaketLes - Create a new lesson package
func CreatePaketLes(c *gin.Context) {
	var req models.CreatePaketLesRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request data",
			"detail":  err.Error(),
		})
		return
	}

	// Validate required fields
	if req.NamaPaket == "" || req.HargaAwal <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Missing required fields: nama_paket, harga_awal",
		})
		return
	}

	// Default status to 'aktif' if not provided
	status := req.Status
	if status == "" {
		status = "aktif"
	}

	// Parse date fields
	tanggalMulai := parseDate(req.TanggalMulaiPromo)
	tanggalSelesai := parseDate(req.TanggalSelesaiPromo)

	var paketID int

	// Insert into database
	err := config.DB.QueryRow(context.Background(), `
		INSERT INTO paket_les (
			nama_paket, harga_awal, diskon, tanggal_mulai_promo, tanggal_selesai_promo,
			deskripsi, durasi, status
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id
	`, req.NamaPaket, req.HargaAwal, req.Diskon, tanggalMulai,
		tanggalSelesai, req.Deskripsi, req.Durasi, status).Scan(&paketID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to create paket les",
			"detail":  err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Paket les berhasil dibuat",
		"data": gin.H{
			"id":         paketID,
			"nama_paket": req.NamaPaket,
			"harga_awal": req.HargaAwal,
			"diskon":     req.Diskon,
			"status":     status,
		},
	})
}

// GetPaketLesList - Get all lesson packages with filters
func GetPaketLesList(c *gin.Context) {
	// Get filter parameters
	status := c.Query("status")
	search := c.Query("search")

	query := `
		SELECT id, nama_paket, harga_awal, diskon, tanggal_mulai_promo, tanggal_selesai_promo,
		       deskripsi, durasi, status, created_at
		FROM paket_les
		WHERE 1=1
	`
	var args []interface{}
	argCount := 1

	// Apply filters
	if status != "" {
		query += ` AND status = $` + strconv.Itoa(argCount)
		args = append(args, status)
		argCount++
	}

	if search != "" {
		query += ` AND nama_paket ILIKE $` + strconv.Itoa(argCount)
		args = append(args, "%"+search+"%")
		argCount++
	}

	query += ` ORDER BY created_at DESC`

	rows, err := config.DB.Query(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to fetch paket les list",
			"detail":  err.Error(),
		})
		return
	}
	defer rows.Close()

	var paketList []models.PaketLes

	for rows.Next() {
		var paket models.PaketLes
		err := rows.Scan(
			&paket.ID, &paket.NamaPaket, &paket.HargaAwal, &paket.Diskon,
			&paket.TanggalMulaiPromo, &paket.TanggalSelesaiPromo,
			&paket.Deskripsi, &paket.Durasi, &paket.Status, &paket.CreatedAt,
		)
		if err != nil {
			continue
		}
		paketList = append(paketList, paket)
	}

	if paketList == nil {
		paketList = []models.PaketLes{}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Paket les list fetched successfully",
		"data":    paketList,
		"count":   len(paketList),
	})
}

// GetPaketLesDetail - Get single lesson package detail
func GetPaketLesDetail(c *gin.Context) {
	id := c.Param("id")

	paketID, err := strconv.Atoi(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid paket ID",
		})
		return
	}

	var paket models.PaketLes

	err = config.DB.QueryRow(context.Background(), `
		SELECT id, nama_paket, harga_awal, diskon, tanggal_mulai_promo, tanggal_selesai_promo,
		       deskripsi, durasi, status, created_at
		FROM paket_les
		WHERE id = $1
	`, paketID).Scan(
		&paket.ID, &paket.NamaPaket, &paket.HargaAwal, &paket.Diskon,
		&paket.TanggalMulaiPromo, &paket.TanggalSelesaiPromo,
		&paket.Deskripsi, &paket.Durasi, &paket.Status, &paket.CreatedAt,
	)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Paket les not found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Paket les detail fetched successfully",
		"data":    paket,
	})
}

// UpdatePaketLes - Update lesson package
func UpdatePaketLes(c *gin.Context) {
	id := c.Param("id")

	paketID, err := strconv.Atoi(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid paket ID",
		})
		return
	}

	var req models.UpdatePaketLesRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request data",
			"detail":  err.Error(),
		})
		return
	}

	// Check if paket exists
	var existID int
	err = config.DB.QueryRow(context.Background(), `
		SELECT id FROM paket_les WHERE id = $1
	`, paketID).Scan(&existID)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Paket les not found",
		})
		return
	}

	// Parse date fields
	tanggalMulai := parseDate(req.TanggalMulaiPromo)
	tanggalSelesai := parseDate(req.TanggalSelesaiPromo)

	// Update the paket
	_, err = config.DB.Exec(context.Background(), `
		UPDATE paket_les SET
			nama_paket = COALESCE(NULLIF($1, ''), nama_paket),
			harga_awal = CASE WHEN $2 > 0 THEN $2 ELSE harga_awal END,
			diskon = CASE WHEN $3 >= 0 THEN $3 ELSE diskon END,
			tanggal_mulai_promo = COALESCE($4, tanggal_mulai_promo),
			tanggal_selesai_promo = COALESCE($5, tanggal_selesai_promo),
			deskripsi = COALESCE(NULLIF($6, ''), deskripsi),
			durasi = CASE WHEN $7 > 0 THEN $7 ELSE durasi END,
			status = COALESCE(NULLIF($8, ''), status)
		WHERE id = $9
	`, req.NamaPaket, req.HargaAwal, req.Diskon, tanggalMulai,
		tanggalSelesai, req.Deskripsi, req.Durasi, req.Status, paketID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to update paket les",
			"detail":  err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Paket les berhasil diperbarui",
		"data": gin.H{
			"id": paketID,
		},
	})
}

// DeletePaketLes - Delete lesson package
func DeletePaketLes(c *gin.Context) {
	id := c.Param("id")

	paketID, err := strconv.Atoi(id)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid paket ID",
		})
		return
	}

	// Get paket name before delete (for response)
	var namaPaket string
	err = config.DB.QueryRow(context.Background(), `
		SELECT nama_paket FROM paket_les WHERE id = $1
	`, paketID).Scan(&namaPaket)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Paket les not found",
		})
		return
	}

	// Delete the paket
	_, err = config.DB.Exec(context.Background(), `
		DELETE FROM paket_les WHERE id = $1
	`, paketID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Failed to delete paket les",
			"detail":  err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Paket les berhasil dihapus",
		"data": gin.H{
			"id":         paketID,
			"nama_paket": namaPaket,
		},
	})
}

// GetPaketLesStats - Get summary stats for dashboard
func GetPaketLesStats(c *gin.Context) {
	var totalPaket int
	var aktivPaket int

	// Total paket
	config.DB.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM paket_les
	`).Scan(&totalPaket)

	// Paket aktif
	config.DB.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM paket_les WHERE status = 'aktif'
	`).Scan(&aktivPaket)

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Paket les stats fetched successfully",
		"data": gin.H{
			"total_paket": totalPaket,
			"paket_aktif": aktivPaket,
		},
	})
}
