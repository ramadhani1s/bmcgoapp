package handlers

import (
	"context"
	"strings"

	"bmcgoapp-backend/config"

	"github.com/gin-gonic/gin"
)

// ===============================
// GET ALL MENTOR
// ===============================
func GetMentors(c *gin.Context) {
	rows, err := config.DB.Query(context.Background(), `
		SELECT 
			id,
			nama_mentor,
			email,
			password,
			mata_pelajaran,
			status
		FROM mentor
		ORDER BY id ASC
	`)
	if err != nil {
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}
	defer rows.Close()

	var mentors []gin.H

	for rows.Next() {
		var (
			id            int
			nama          string
			email         string
			password      string
			mataPelajaran string
			status        string
		)

		err := rows.Scan(
			&id,
			&nama,
			&email,
			&password,
			&mataPelajaran,
			&status,
		)

		if err != nil {
			c.JSON(500, gin.H{
				"error": err.Error(),
			})
			return
		}

		mentors = append(mentors, gin.H{
			"id":             id,
			"mentor_id":      id,
			"nama":           nama,
			"nama_mentor":    nama,
			"email":          email,
			"password":       password,
			"mapel":          mataPelajaran,
			"mata_pelajaran": mataPelajaran,
			"spesialisasi":   mataPelajaran,
			"status":         status,
		})
	}

	c.JSON(200, mentors)
}

// ===============================
// CREATE MENTOR
// ===============================
func CreateMentor(c *gin.Context) {
	var input struct {
		NamaMentor    string `json:"nama_mentor"`
		Email         string `json:"email"`
		Password      string `json:"password"`
		MataPelajaran string `json:"mata_pelajaran"`
		Status        string `json:"status"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(400, gin.H{
			"error": "Data tidak valid",
		})
		return
	}

	input.NamaMentor = strings.TrimSpace(input.NamaMentor)
	input.Email = strings.TrimSpace(input.Email)
	input.Password = strings.TrimSpace(input.Password)
	input.MataPelajaran = strings.TrimSpace(input.MataPelajaran)
	input.Status = strings.TrimSpace(input.Status)

	if input.NamaMentor == "" ||
		input.Email == "" ||
		input.Password == "" ||
		input.MataPelajaran == "" {
		c.JSON(400, gin.H{
			"error": "Nama, email, password, dan mata pelajaran wajib diisi",
		})
		return
	}

	if input.Status == "" {
		input.Status = "Aktif"
	}

	_, err := config.DB.Exec(context.Background(), `
		INSERT INTO mentor
		(
			nama_mentor,
			email,
			password,
			mata_pelajaran,
			status
		)
		VALUES ($1,$2,$3,$4,$5)
	`,
		input.NamaMentor,
		input.Email,
		input.Password,
		input.MataPelajaran,
		input.Status,
	)

	if err != nil {
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"message": "Mentor berhasil ditambahkan",
	})
}

// ===============================
// UPDATE MENTOR
// ===============================
func UpdateMentor(c *gin.Context) {
	id := c.Param("id")

	var input struct {
		NamaMentor    string `json:"nama_mentor"`
		Email         string `json:"email"`
		Password      string `json:"password"`
		MataPelajaran string `json:"mata_pelajaran"`
		Status        string `json:"status"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(400, gin.H{"error": "Data tidak valid"})
		return
	}

	// kalau password diisi → update password juga
	if strings.TrimSpace(input.Password) != "" {

		_, err := config.DB.Exec(context.Background(), `
			UPDATE mentor
			SET nama_mentor=$1,
				email=$2,
				password=$3,
				mata_pelajaran=$4,
				status=$5
			WHERE id=$6
		`,
			input.NamaMentor,
			input.Email,
			input.Password,
			input.MataPelajaran,
			input.Status,
			id,
		)

		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}

	} else {

		_, err := config.DB.Exec(context.Background(), `
			UPDATE mentor
			SET nama_mentor=$1,
				email=$2,
				mata_pelajaran=$3,
				status=$4
			WHERE id=$5
		`,
			input.NamaMentor,
			input.Email,
			input.MataPelajaran,
			input.Status,
			id,
		)

		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
	}

	c.JSON(200, gin.H{
		"success": true,
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
		`DELETE FROM mentor WHERE id=$1`,
		id,
	)

	if err != nil {
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"message": "Mentor berhasil dihapus",
	})
}
