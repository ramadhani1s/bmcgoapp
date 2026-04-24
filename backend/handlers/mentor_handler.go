package handlers

import (
	"context"

	"bmcgoapp-backend/config"
	"github.com/gin-gonic/gin"
)

// ===============================
// GET ALL MENTOR
// ===============================
func GetMentors(c *gin.Context) {
	rows, err := config.DB.Query(context.Background(), `
		SELECT id, nama_mentor, email, spesialisasi, status
		FROM mentor
		ORDER BY id ASC
	`)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	var mentors []gin.H

	for rows.Next() {
		var id int
		var nama, email, mapel, status string

		err := rows.Scan(&id, &nama, &email, &mapel, &status)
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}

		mentors = append(mentors, gin.H{
			"id":     id,
			"nama":   nama,
			"email":  email,
			"mapel":  mapel,
			"status": status,
		})
	}

	c.JSON(200, mentors)
}

// ===============================
// CREATE MENTOR
// ===============================
func CreateMentor(c *gin.Context) {
	var input struct {
		NamaMentor   string `json:"nama_mentor"`
		Email        string `json:"email"`
		Spesialisasi string `json:"spesialisasi"`
		Bio          string `json:"bio"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(400, gin.H{"error": "Data tidak valid"})
		return
	}

	if input.NamaMentor == "" || input.Email == "" || input.Spesialisasi == "" {
		c.JSON(400, gin.H{"error": "Nama, email, dan spesialisasi wajib diisi"})
		return
	}

	_, err := config.DB.Exec(context.Background(), `
		INSERT INTO mentor (nama_mentor, email, spesialisasi, bio, status)
		VALUES ($1, $2, $3, $4, 'Aktif')
	`,
		input.NamaMentor,
		input.Email,
		input.Spesialisasi,
		input.Bio,
	)

	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"message": "Mentor berhasil ditambahkan",
	})
}

// ===============================
// UPDATE MENTOR
// ===============================
func UpdateMentor(c *gin.Context) {
	id := c.Param("id")

	var input struct {
		NamaMentor   string `json:"nama_mentor"`
		Email        string `json:"email"`
		Spesialisasi string `json:"spesialisasi"`
		Bio          string `json:"bio"`
		Status       string `json:"status"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(400, gin.H{"error": "Data tidak valid"})
		return
	}

	_, err := config.DB.Exec(context.Background(), `
		UPDATE mentor
		SET nama_mentor=$1,
		    email=$2,
		    spesialisasi=$3,
		    bio=$4,
		    status=$5
		WHERE id=$6
	`,
		input.NamaMentor,
		input.Email,
		input.Spesialisasi,
		input.Bio,
		input.Status,
		id,
	)

	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"message": "Mentor berhasil diupdate",
	})
}

// ===============================
// DELETE MENTOR
// ===============================
func DeleteMentor(c *gin.Context) {
	id := c.Param("id")

	_, err := config.DB.Exec(
		context.Background(),
		"DELETE FROM mentor WHERE id=$1",
		id,
	)

	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{
		"message": "Mentor berhasil dihapus",
	})
}