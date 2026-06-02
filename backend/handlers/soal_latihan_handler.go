package handlers

import (
	"net/http"
	"strconv"

	"bmcgoapp-backend/models"
	"bmcgoapp-backend/services"

	"github.com/gin-gonic/gin"
)

func GetSoalLatihanHandler(c *gin.Context) {
	userIDRaw, _ := c.Get("user_id")
	userID := userIDRaw.(int)

	items, err := services.GetSoalLatihanByMentorUserID(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal mengambil soal latihan",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Soal latihan berhasil diambil",
		"data":    items,
	})
}

func CreateSoalLatihanHandler(c *gin.Context) {
	userIDRaw, _ := c.Get("user_id")
	userID := userIDRaw.(int)

	var input models.SoalLatihan
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Format request tidak valid",
			"details": err.Error(),
		})
		return
	}

	created, err := services.CreateSoalLatihan(userID, input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal menambah soal latihan",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Soal latihan berhasil ditambahkan",
		"data":    created,
	})
}

func UpdateSoalLatihanHandler(c *gin.Context) {
	userIDRaw, _ := c.Get("user_id")
	userID := userIDRaw.(int)

	soalID, err := strconv.Atoi(c.Param("soalId"))
	if err != nil || soalID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "soalId tidak valid",
		})
		return
	}

	var input models.SoalLatihan
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Format request tidak valid",
			"details": err.Error(),
		})
		return
	}

	updated, err := services.UpdateSoalLatihan(userID, soalID, input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal update soal latihan",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Soal latihan berhasil diupdate",
		"data":    updated,
	})
}

func DeleteSoalLatihanHandler(c *gin.Context) {
	userIDRaw, _ := c.Get("user_id")
	userID := userIDRaw.(int)

	soalID, err := strconv.Atoi(c.Param("soalId"))
	if err != nil || soalID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "soalId tidak valid",
		})
		return
	}

	if err := services.DeleteSoalLatihan(userID, soalID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal hapus soal latihan",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Soal latihan berhasil dihapus",
	})
}

// GetSoalLatihanSiswa mengambil soal latihan berdasarkan subject untuk siswa
func GetSoalLatihanSiswa(c *gin.Context) {
	subject := c.Query("subject")

	items, err := services.GetSoalLatihanBySubject(subject)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal mengambil soal latihan",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Soal latihan berhasil diambil",
		"data":    items,
	})
}
