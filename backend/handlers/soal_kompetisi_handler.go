package handlers

import (
	"context"
	"net/http"
	"strconv"

	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
	"bmcgoapp-backend/services"

	"github.com/gin-gonic/gin"
)

// ============= TRYOUT SOAL HANDLERS =============

func GetTryoutSoalHandler(c *gin.Context) {
	kompetisiID, err := strconv.Atoi(c.Query("kompetisi_id"))
	if err != nil || kompetisiID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "kompetisi_id harus berupa angka positif",
		})
		return
	}

	items, err := services.GetTryoutSoal(kompetisiID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal mengambil soal try out",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Soal try out berhasil diambil",
		"data":    items,
	})
}

func CreateTryoutSoalHandler(c *gin.Context) {
	kompetisiID, err := strconv.Atoi(c.Query("kompetisi_id"))
	if err != nil || kompetisiID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "kompetisi_id harus berupa angka positif",
		})
		return
	}

	var input models.SoalKompetisi
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Format request tidak valid",
			"details": err.Error(),
		})
		return
	}

	// 🔥 VALIDASI TRYOUT: Ambil total_questions dari tabel tryout
	var totalQuestions int
	err = config.DB.QueryRow(context.Background(), `
		SELECT total_questions FROM tryout WHERE id = $1
	`, kompetisiID).Scan(&totalQuestions)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Gagal mengambil data tryout",
		})
		return
	}

	// 🔥 VALIDASI TRYOUT: Hitung jumlah soal yang sudah ada
	var currentSoalCount int
	err = config.DB.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM tryout_soal WHERE kompetisi_id = $1
	`, kompetisiID).Scan(&currentSoalCount)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Gagal menghitung jumlah soal",
		})
		return
	}

	// 🔥 VALIDASI TRYOUT: Cek apakah sudah mencapai batas
	if currentSoalCount >= totalQuestions {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Tidak dapat menambah soal! Batas maksimal " + strconv.Itoa(totalQuestions) + " soal sudah tercapai.",
			"details": gin.H{
				"total_batas":  totalQuestions,
				"soal_terbuat": currentSoalCount,
				"sisa_kuota":   totalQuestions - currentSoalCount,
			},
		})
		return
	}

	input.Tipe = "tryout"
	input.KompetisiID = kompetisiID
	created, err := services.CreateTryoutSoal(input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal membuat soal try out",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Soal try out berhasil dibuat",
		"data":    created,
	})
}

func UpdateTryoutSoalHandler(c *gin.Context) {
	soalID, err := strconv.Atoi(c.Param("id"))
	if err != nil || soalID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "id tidak valid",
		})
		return
	}

	var input models.SoalKompetisi
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Format request tidak valid",
			"details": err.Error(),
		})
		return
	}

	input.Tipe = "tryout"
	updated, err := services.UpdateTryoutSoal(soalID, input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal update soal try out",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Soal try out berhasil diupdate",
		"data":    updated,
	})
}

func DeleteTryoutSoalHandler(c *gin.Context) {
	soalID, err := strconv.Atoi(c.Param("id"))
	if err != nil || soalID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "id tidak valid",
		})
		return
	}

	if err := services.DeleteTryoutSoal(soalID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal hapus soal try out",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Soal try out berhasil dihapus",
	})
}
// ============= OLIMPIADE SOAL HANDLERS =============

func GetOlimpiadeSoalHandler(c *gin.Context) {
	kompetisiID, err := strconv.Atoi(c.Query("kompetisi_id"))
	if err != nil || kompetisiID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "kompetisi_id harus berupa angka positif",
		})
		return
	}

	items, err := services.GetOlimpiadeSoal(kompetisiID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal mengambil soal olimpiade",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Soal olimpiade berhasil diambil",
		"data":    items,
	})
}

func CreateOlimpiadeSoalHandler(c *gin.Context) {
	kompetisiID, err := strconv.Atoi(c.Query("kompetisi_id"))
	if err != nil || kompetisiID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "kompetisi_id harus berupa angka positif",
		})
		return
	}

	var input models.SoalKompetisi
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Format request tidak valid",
			"details": err.Error(),
		})
		return
	}

	// 🔥 VALIDASI OLIMPIADE: Ambil total_questions dari tabel olimpiade
	var totalQuestions int
	err = config.DB.QueryRow(context.Background(), `
		SELECT total_questions FROM olimpiade WHERE id = $1
	`, kompetisiID).Scan(&totalQuestions)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Gagal mengambil data olimpiade",
		})
		return
	}

	// 🔥 VALIDASI OLIMPIADE: Hitung jumlah soal yang sudah ada
	var currentSoalCount int
	err = config.DB.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM olimpiade_soal WHERE kompetisi_id = $1
	`, kompetisiID).Scan(&currentSoalCount)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Gagal menghitung jumlah soal",
		})
		return
	}

	// 🔥 VALIDASI OLIMPIADE: Cek apakah sudah mencapai batas
	if currentSoalCount >= totalQuestions {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Tidak dapat menambah soal! Batas maksimal " + strconv.Itoa(totalQuestions) + " soal sudah tercapai.",
			"details": gin.H{
				"total_batas":  totalQuestions,
				"soal_terbuat": currentSoalCount,
				"sisa_kuota":   totalQuestions - currentSoalCount,
			},
		})
		return
	}

	input.Tipe = "olimpiade"
	input.KompetisiID = kompetisiID
	created, err := services.CreateOlimpiadeSoal(input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal membuat soal olimpiade",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Soal olimpiade berhasil dibuat",
		"data":    created,
	})
}

func UpdateOlimpiadeSoalHandler(c *gin.Context) {
	soalID, err := strconv.Atoi(c.Param("id"))
	if err != nil || soalID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "id tidak valid",
		})
		return
	}

	var input models.SoalKompetisi
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Format request tidak valid",
			"details": err.Error(),
		})
		return
	}

	input.Tipe = "olimpiade"
	updated, err := services.UpdateOlimpiadeSoal(soalID, input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal update soal olimpiade",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Soal olimpiade berhasil diupdate",
		"data":    updated,
	})
}

func DeleteOlimpiadeSoalHandler(c *gin.Context) {
	soalID, err := strconv.Atoi(c.Param("id"))
	if err != nil || soalID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "id tidak valid",
		})
		return
	}

	if err := services.DeleteOlimpiadeSoal(soalID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal hapus soal olimpiade",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Soal olimpiade berhasil dihapus",
	})
}