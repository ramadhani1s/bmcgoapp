package handlers

import (
	"context"
	"net/http"
	"regexp"
	"strings"
	"fmt"

	"bmcgoapp-backend/config"
	"github.com/gin-gonic/gin"
)

// SimpanHasilLatihan saves the score of a completed Latihan Soal
func SimpanHasilLatihan(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	siswaID := userID.(int)

	var payload struct {
		MateriID     int    `json:"materi_id"`
		LatihanTitle string `json:"latihan_title"`
		Skor         int    `json:"skor"`
		TotalSoal    int    `json:"total_soal"`
	}

	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload", "details": err.Error()})
		return
	}

	// Upsert to handle multiple attempts
	_, err := config.DB.Exec(context.Background(), `
		INSERT INTO hasil_latihan (siswa_id, materi_id, latihan_title, skor, total_soal)
		VALUES ((SELECT id FROM siswa WHERE user_id = $1), $2, $3, $4, $5)
		ON CONFLICT (siswa_id, materi_id, latihan_title) 
		DO UPDATE SET skor = EXCLUDED.skor, total_soal = EXCLUDED.total_soal, created_at = CURRENT_TIMESTAMP
	`, siswaID, payload.MateriID, payload.LatihanTitle, payload.Skor, payload.TotalSoal)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan hasil latihan", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Hasil latihan berhasil disimpan"})
}

// GetSiswaProgress calculates the overall progress
func GetSiswaProgress(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	siswaID := userID.(int)

	// Get student's class level
	var classLevel string
	err := config.DB.QueryRow(context.Background(), "SELECT class_level FROM siswa WHERE user_id = $1", siswaID).Scan(&classLevel)
	if err != nil {
		// fallback to empty or handle
		classLevel = ""
	}

	// 1. Calculate Total Assigned Latihan Soal
	// Fetch all questions for this class
	rows, err := config.DB.Query(context.Background(), `
		SELECT sl.materi_id, sl.pertanyaan 
		FROM soal_latihan sl 
		JOIN learning_materials lm ON sl.materi_id = lm.id 
		WHERE lm.class_level = $1
	`, classLevel)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil data soal", "details": err.Error()})
		return
	}
	defer rows.Close()

	uniqueLatihan := make(map[string]bool)
	for rows.Next() {
		var mID int
		var pertanyaan string
		if err := rows.Scan(&mID, &pertanyaan); err != nil {
			continue
		}
		if strings.Contains(pertanyaan, "[SKELETON]") {
			continue
		}

		title := "Latihan Soal"
		// Regex to parse title
		titleMatch := regexp.MustCompile(`\[Latihan:(.*?)\]`).FindStringSubmatch(pertanyaan)
		if len(titleMatch) > 1 {
			title = strings.TrimSpace(titleMatch[1])
		} else {
			oldFormatMatch := regexp.MustCompile(`^\[.*?\]\[.*?\]\[(.*?)\]`).FindStringSubmatch(pertanyaan)
			if len(oldFormatMatch) > 1 && !strings.Contains(oldFormatMatch[1], ":") {
				title = strings.TrimSpace(oldFormatMatch[1])
			}
		}

		key := fmt.Sprintf("%d-%s", mID, title)
		uniqueLatihan[key] = true
	}

	totalLatihan := len(uniqueLatihan)

	// 2. Calculate Completed Latihan
	var completedLatihan int
	err = config.DB.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM hasil_latihan WHERE siswa_id = (SELECT id FROM siswa WHERE user_id = $1)
	`, siswaID).Scan(&completedLatihan)
	if err != nil {
		completedLatihan = 0
	}

	// 3. Calculate Total Assigned Tryouts
	var totalTryout int
	err = config.DB.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM tryout WHERE class_level = $1
	`, classLevel).Scan(&totalTryout)
	if err != nil {
		totalTryout = 0
	}

	// 4. Calculate Completed Tryouts
	var completedTryout int
	err = config.DB.QueryRow(context.Background(), `
		SELECT COUNT(DISTINCT tryout_id) FROM hasil_tryout WHERE siswa_id = (SELECT id FROM siswa WHERE user_id = $1)
	`, siswaID).Scan(&completedTryout)
	if err != nil {
		completedTryout = 0
	}

	// Calculate overall percentage
	totalAssigned := totalLatihan + totalTryout
	totalCompleted := completedLatihan + completedTryout

	percentage := 0
	if totalAssigned > 0 {
		percentage = (totalCompleted * 100) / totalAssigned
	}

	c.JSON(http.StatusOK, gin.H{
		"percentage":        percentage,
		"total_latihan":     totalLatihan,
		"completed_latihan": completedLatihan,
		"total_tryout":      totalTryout,
		"completed_tryout":  completedTryout,
	})
}
