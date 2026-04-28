package handlers

import (
	"net/http"
	"strconv"

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
	var input models.SoalKompetisi
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Format request tidak valid",
			"details": err.Error(),
		})
		return
	}

	input.Tipe = "tryout"
	created, err := services.CreateTryoutSoal(input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal membuat soal try out",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
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
		"message": "Soal try out berhasil dihapus",
	})
}

// ============= OLIMPIADE SOAL HANDLERS =============

func GetOlimpiadseSoalHandler(c *gin.Context) {
	kompetisiID, err := strconv.Atoi(c.Query("kompetisi_id"))
	if err != nil || kompetisiID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "kompetisi_id harus berupa angka positif",
		})
		return
	}

	items, err := services.GetOlimpiadseSoal(kompetisiID)
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

func CreateOlimpiadseSoalHandler(c *gin.Context) {
	var input models.SoalKompetisi
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Format request tidak valid",
			"details": err.Error(),
		})
		return
	}

	input.Tipe = "olimpiade"
	created, err := services.CreateOlimpiadseSoal(input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal membuat soal olimpiade",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Soal olimpiade berhasil dibuat",
		"data":    created,
	})
}

func UpdateOlimpiadseSoalHandler(c *gin.Context) {
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
	updated, err := services.UpdateOlimpiadseSoal(soalID, input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal update soal olimpiade",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Soal olimpiade berhasil diupdate",
		"data":    updated,
	})
}

func DeleteOlimpiadseSoalHandler(c *gin.Context) {
	soalID, err := strconv.Atoi(c.Param("id"))
	if err != nil || soalID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "id tidak valid",
		})
		return
	}

	if err := services.DeleteOlimpiadseSoal(soalID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal hapus soal olimpiade",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Soal olimpiade berhasil dihapus",
	})
}
