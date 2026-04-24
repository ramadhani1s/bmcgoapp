package handlers

import (
	"net/http"
	"strconv"

	"bmcgoapp-backend/services"

	"github.com/gin-gonic/gin"
)

type createMentorRequest struct {
	Email        string `json:"email"`
	Password     string `json:"password"`
	NamaMentor   string `json:"nama_mentor"`
	Spesialisasi string `json:"spesialisasi"`
	Bio          string `json:"bio"`
}

func CreateMentorHandler(c *gin.Context) {
	var req createMentorRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Format request tidak valid",
			"details": err.Error(),
		})
		return
	}

	if err := services.CreateMentor(req.Email, req.Password, req.NamaMentor, req.Spesialisasi, req.Bio); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal membuat mentor",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Mentor berhasil dibuat",
	})
}

func GetMentorsHandler(c *gin.Context) {
	items, err := services.GetMentors()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Gagal mengambil data mentor",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Data mentor berhasil diambil",
		"data":    items,
	})
}

func DeleteMentorHandler(c *gin.Context) {
	mentorID, err := strconv.Atoi(c.Param("mentorId"))
	if err != nil || mentorID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "mentorId tidak valid",
		})
		return
	}

	if err := services.DeleteMentorByID(mentorID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Gagal menghapus mentor",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Mentor berhasil dihapus",
	})
}
