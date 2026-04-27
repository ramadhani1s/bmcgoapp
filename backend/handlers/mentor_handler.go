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
			spesialisasi,
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
			id           int
			nama         string
			email        string
			password     string
			spesialisasi string
			status       string
		)

		err := rows.Scan(
			&id,
			&nama,
			&email,
			&password,
			&spesialisasi,
			&status,
		)

		if err != nil {
			c.JSON(500, gin.H{
				"error": err.Error(),
			})
			return
		}

		mentors = append(mentors, gin.H{
			"id":           id,
			"mentor_id":    id,
			"nama":         nama,
			"nama_mentor":  nama,
			"email":        email,
			"password":     password,
			"mapel":        spesialisasi,
			"spesialisasi": spesialisasi,
			"status":       status,
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
		Password     string `json:"password"`
		Spesialisasi string `json:"spesialisasi"`
		Status       string `json:"status"`
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
	input.Spesialisasi = strings.TrimSpace(input.Spesialisasi)
	input.Status = strings.TrimSpace(input.Status)

	if input.NamaMentor == "" ||
		input.Email == "" ||
		input.Password == "" ||
		input.Spesialisasi == "" {
		c.JSON(400, gin.H{
			"error": "Nama, email, password, dan spesialisasi wajib diisi",
		})
		return
	}

	if input.Status == "" {
		input.Status = "Aktif"
	}

	// =====================================================
	// FIX: support jika tabel mentor masih punya kolom bio
	// =====================================================

	_, err := config.DB.Exec(context.Background(), `
		INSERT INTO mentor
		(
			nama_mentor,
			email,
			password,
			spesialisasi,
			status
		)
		VALUES ($1,$2,$3,$4,$5)
	`,
		input.NamaMentor,
		input.Email,
		input.Password,
		input.Spesialisasi,
		input.Status,
	)

	if err != nil {

		// jika DB masih punya kolom bio NOT NULL
		if strings.Contains(strings.ToLower(err.Error()), "bio") {

			_, err = config.DB.Exec(context.Background(), `
				INSERT INTO mentor
				(
					nama_mentor,
					email,
					password,
					spesialisasi,
					status,
					bio
				)
				VALUES ($1,$2,$3,$4,$5,$6)
			`,
				input.NamaMentor,
				input.Email,
				input.Password,
				input.Spesialisasi,
				input.Status,
				"-",
			)

			if err != nil {
				c.JSON(500, gin.H{
					"error": err.Error(),
				})
				return
			}

		} else {
			c.JSON(500, gin.H{
				"error": err.Error(),
			})
			return
		}
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
		NamaMentor   string `json:"nama_mentor"`
		Email        string `json:"email"`
		Password     string `json:"password"`
		Spesialisasi string `json:"spesialisasi"`
		Status       string `json:"status"`
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
				spesialisasi=$4,
				status=$5
			WHERE id=$6
		`,
			input.NamaMentor,
			input.Email,
			input.Password,
			input.Spesialisasi,
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
				spesialisasi=$3,
				status=$4
			WHERE id=$5
		`,
			input.NamaMentor,
			input.Email,
			input.Spesialisasi,
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