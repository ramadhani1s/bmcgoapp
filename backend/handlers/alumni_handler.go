package handlers

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"bmcgoapp-backend/config"

	"github.com/gin-gonic/gin"
)

// GetAlumniHandler retrieves all alumni
func GetAlumniHandler(c *gin.Context) {
	rows, err := config.DB.Query(context.Background(), `
SELECT 
id,
nama,
sekolah,
tahun_lulus,
COALESCE(prestasi, ''),
COALESCE(foto, '')
FROM alumni
ORDER BY id DESC
`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	var alumni []gin.H
	for rows.Next() {
		var (
			id, tahunLulus                int
			nama, sekolah, prestasi, foto string
		)

		if err := rows.Scan(&id, &nama, &sekolah, &tahunLulus, &prestasi, &foto); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		alumni = append(alumni, gin.H{
			"id":          id,
			"nama":        nama,
			"sekolah":     sekolah,
			"tahun_lulus": tahunLulus,
			"prestasi":    prestasi,
			"foto":        foto,
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": alumni})
}

// GetAlumniByIdHandler retrieves a specific alumni by ID
func GetAlumniByIdHandler(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID alumni tidak valid"})
		return
	}

	var (
		nama, sekolah, prestasi, foto string
		tahunLulus                    int
	)

	err = config.DB.QueryRow(context.Background(), `
SELECT 
id,
nama,
sekolah,
tahun_lulus,
COALESCE(prestasi, ''),
COALESCE(foto, '')
FROM alumni
WHERE id = $1
`, id).Scan(&id, &nama, &sekolah, &tahunLulus, &prestasi, &foto)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Alumni tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": gin.H{
			"id":          id,
			"nama":        nama,
			"sekolah":     sekolah,
			"tahun_lulus": tahunLulus,
			"prestasi":    prestasi,
			"foto":        foto,
		},
	})
}

// CreateAlumniHandler creates a new alumni
func CreateAlumniHandler(c *gin.Context) {
	var req gin.H
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format data tidak valid"})
		return
	}

	nama, _ := req["nama"].(string)
	sekolah, _ := req["sekolah"].(string)
	nama = strings.TrimSpace(nama)
	sekolah = strings.TrimSpace(sekolah)

	if nama == "" || sekolah == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Nama dan sekolah harus diisi"})
		return
	}

	tahunLulus := 2024
	if val, ok := req["tahun_lulus"]; ok {
		switch v := val.(type) {
		case float64:
			tahunLulus = int(v)
		case string:
			if parsed, err := strconv.Atoi(v); err == nil {
				tahunLulus = parsed
			}
		}
	}

	prestasi := ""
	if val, ok := req["prestasi"]; ok {
		prestasi = strings.TrimSpace(fmt.Sprint(val))
	}

	foto := ""
	if val, ok := req["foto"]; ok {
		foto = strings.TrimSpace(fmt.Sprint(val))
	}

	var newID int
	err := config.DB.QueryRow(context.Background(), `
INSERT INTO alumni (nama, sekolah, tahun_lulus, prestasi, foto)
VALUES ($1, $2, $3, $4, $5)
RETURNING id
`, nama, sekolah, tahunLulus, prestasi, foto).Scan(&newID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Gagal menambahkan alumni: %v", err)})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Alumni berhasil ditambahkan",
		"id":      newID,
	})
}

// UpdateAlumniHandler updates an existing alumni
func UpdateAlumniHandler(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID alumni tidak valid"})
		return
	}

	var req gin.H
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format data tidak valid"})
		return
	}

	nama, _ := req["nama"].(string)
	sekolah, _ := req["sekolah"].(string)
	nama = strings.TrimSpace(nama)
	sekolah = strings.TrimSpace(sekolah)

	if nama == "" || sekolah == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Nama dan sekolah harus diisi"})
		return
	}

	tahunLulus := 2024
	if val, ok := req["tahun_lulus"]; ok {
		switch v := val.(type) {
		case float64:
			tahunLulus = int(v)
		case string:
			if parsed, err := strconv.Atoi(v); err == nil {
				tahunLulus = parsed
			}
		}
	}

	prestasi := ""
	if val, ok := req["prestasi"]; ok {
		prestasi = strings.TrimSpace(fmt.Sprint(val))
	}

	foto := ""
	if val, ok := req["foto"]; ok {
		foto = strings.TrimSpace(fmt.Sprint(val))
	}

	_, err = config.DB.Exec(context.Background(), `
UPDATE alumni 
SET nama = $1, sekolah = $2, tahun_lulus = $3, prestasi = $4, foto = $5
WHERE id = $6
`, nama, sekolah, tahunLulus, prestasi, foto, id)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Gagal memperbarui alumni: %v", err)})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alumni berhasil diperbarui"})
}

// DeleteAlumniHandler deletes an alumni
func DeleteAlumniHandler(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID alumni tidak valid"})
		return
	}

	_, err = config.DB.Exec(context.Background(), `
DELETE FROM alumni WHERE id = $1
`, id)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menghapus alumni"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alumni berhasil dihapus"})
}
