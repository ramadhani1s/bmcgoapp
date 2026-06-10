package handlers

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// CreateJadwal - Create new jadwal
func CreateJadwal(c *gin.Context) {
	var req models.CreateJadwalRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Invalid request data", "detail": err.Error()})
		return
	}

	// Validate all required fields
	if req.PaketID <= 0 || req.MentorID <= 0 || req.ClassLevel == "" || req.MataPelajaran == "" || req.Hari == "" || req.JamMulai == "" || req.JamSelesai == "" || req.Ruang == "" {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Semua field wajib diisi (paket_id, mentor_id, class_level, mata_pelajaran, hari, jam_mulai, jam_selesai, ruang)"})
		return
	}

	// Parse jam
	jamMulai, err := time.Parse("15:04", req.JamMulai)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Format jam_mulai harus HH:MM", "detail": err.Error()})
		return
	}
	jamSelesai, err := time.Parse("15:04", req.JamSelesai)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Format jam_selesai harus HH:MM",
			"detail":  err.Error(),
		})
		return
	}

	var jadwalID int

	// Insert using formatted time strings (HH:MM)
	err = config.DB.QueryRow(context.Background(), `
		INSERT INTO jadwal (paket_id, mentor_id, class_level, mata_pelajaran, hari, jam_mulai, jam_selesai, ruang)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id
	`, req.PaketID, req.MentorID, req.ClassLevel, req.MataPelajaran, req.Hari, jamMulai.Format("15:04"), jamSelesai.Format("15:04"), req.Ruang).Scan(&jadwalID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal membuat jadwal",
			"detail":  err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Jadwal berhasil dibuat",
		"data": gin.H{
			"id": jadwalID,
		},
	})
}

// GetJadwalList - Get all jadwal
func GetJadwalList(c *gin.Context) {
	paketID := c.Query("paket_id")
	mentorID := c.Query("mentor_id")
	hari := c.Query("hari")

	query := `
		SELECT j.id, j.paket_id, j.mentor_id, j.class_level, j.mata_pelajaran, j.hari, to_char(j.jam_mulai, 'HH24:MI') AS waktu_mulai, to_char(j.jam_selesai, 'HH24:MI') AS waktu_selesai, j.ruang, COALESCE(m.nama_mentor, '') AS mentor
		FROM jadwal j
		LEFT JOIN mentor m ON m.id = j.mentor_id
		WHERE 1=1
	`
	var args []interface{}
	argCount := 1

	if paketID != "" {
		query += ` AND j.paket_id = $` + strconv.Itoa(argCount)
		args = append(args, paketID)
		argCount++
	}

	if mentorID != "" {
		query += ` AND j.mentor_id = $` + strconv.Itoa(argCount)
		args = append(args, mentorID)
		argCount++
	}

	if hari != "" {
		query += ` AND j.hari = $` + strconv.Itoa(argCount)
		args = append(args, hari)
		argCount++
	}

	query += ` ORDER BY j.hari, j.jam_mulai`

	rows, err := config.DB.Query(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal fetch jadwal",
			"detail":  err.Error(),
		})
		return
	}
	defer rows.Close()

	var jadwals []models.Jadwal
	for rows.Next() {
		var j models.Jadwal
		if err := rows.Scan(
			&j.ID,
			&j.PaketID,
			&j.MentorID,
			&j.ClassLevel,
			&j.MataPelajaran,
			&j.Hari,
			&j.WaktuMulai,
			&j.WaktuSelesai,
			&j.Ruang,
			&j.Mentor,
		); err != nil {
			fmt.Println("Scan error:", err)
			continue
		}
		j.JamMulai = j.WaktuMulai
		j.JamSelesai = j.WaktuSelesai
		jadwals = append(jadwals, j)
	}

	if jadwals == nil {
		jadwals = []models.Jadwal{}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Jadwal list fetched",
		"data":    jadwals,
		"count":   len(jadwals),
	})
}

// GetMentorJadwalList - Get jadwal milik mentor yang sedang login
func GetMentorJadwalList(c *gin.Context) {

	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{
			"status":  "error",
			"message": err.Error(),
		})
		return
	}

	mentorID, err := resolveMentorID(userID, 0)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Mentor tidak ditemukan",
			"detail":  err.Error(),
		})
		return
	}

	rows, err := config.DB.Query(context.Background(), `
		SELECT
			j.id,
			j.paket_id,
			j.mentor_id,
			j.class_level,
			j.mata_pelajaran,
			j.hari,
			to_char(j.jam_mulai, 'HH24:MI') as waktu_mulai,
			to_char(j.jam_selesai, 'HH24:MI') as waktu_selesai,
			j.ruang,
			COALESCE(m.nama_mentor, '') as mentor
		FROM jadwal j
		LEFT JOIN mentor m ON m.id = j.mentor_id
		WHERE j.mentor_id = $1
		ORDER BY j.hari, j.jam_mulai
	`, mentorID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal fetch jadwal mentor",
			"detail":  err.Error(),
		})
		return
	}
	defer rows.Close()

	var jadwals []models.Jadwal

	for rows.Next() {
		var j models.Jadwal

		if err := rows.Scan(
			&j.ID,
			&j.PaketID,
			&j.MentorID,
			&j.ClassLevel,
			&j.MataPelajaran,
			&j.Hari,
			&j.WaktuMulai,
			&j.WaktuSelesai,
			&j.Ruang,
			&j.Mentor,
		); err != nil {
			continue
		}

		j.JamMulai = j.WaktuMulai
		j.JamSelesai = j.WaktuSelesai
		jadwals = append(jadwals, j)
	}

	if jadwals == nil {
		jadwals = []models.Jadwal{}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Jadwal mentor fetched",
		"data":    jadwals,
		"count":   len(jadwals),
	})
}

// GetJadwalDetail - Get single jadwal
func GetJadwalDetail(c *gin.Context) {
	id := c.Param("id")

	var j models.Jadwal
	err := config.DB.QueryRow(context.Background(), `
		SELECT j.id, j.paket_id, j.mentor_id, j.class_level, j.mata_pelajaran, j.hari, to_char(j.jam_mulai, 'HH24:MI') as waktu_mulai, to_char(j.jam_selesai, 'HH24:MI') as waktu_selesai, j.ruang, COALESCE(m.nama_mentor, '') as mentor
		FROM jadwal j
		LEFT JOIN mentor m ON m.id = j.mentor_id
		WHERE j.id = $1
	`, id).Scan(&j.ID, &j.PaketID, &j.MentorID, &j.ClassLevel, &j.MataPelajaran, &j.Hari, &j.WaktuMulai, &j.WaktuSelesai, &j.Ruang, &j.Mentor)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Jadwal not found",
		})
		return
	}

	j.JamMulai = j.WaktuMulai
	j.JamSelesai = j.WaktuSelesai

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Jadwal detail fetched",
		"data":    j,
	})
}

// UpdateJadwal - Update jadwal
func UpdateJadwal(c *gin.Context) {
	id := c.Param("id")
	var req models.UpdateJadwalRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Invalid request data",
			"detail":  err.Error(),
		})
		return
	}

	query := `UPDATE jadwal SET `
	var updateFields []string
	var args []interface{}
	argCount := 1

	if req.PaketID != nil {
		updateFields = append(updateFields, fmt.Sprintf(`paket_id = $%d`, argCount))
		args = append(args, *req.PaketID)
		argCount++
	}

	if req.MentorID != nil {
		updateFields = append(updateFields, fmt.Sprintf(`mentor_id = $%d`, argCount))
		args = append(args, *req.MentorID)
		argCount++
	}

	if req.ClassLevel != nil {
		updateFields = append(updateFields, fmt.Sprintf(`class_level = $%d`, argCount))
		args = append(args, *req.ClassLevel)
		argCount++
	}

	if req.MataPelajaran != nil {
		updateFields = append(updateFields, fmt.Sprintf(`mata_pelajaran = $%d`, argCount))
		args = append(args, *req.MataPelajaran)
		argCount++
	}

	if req.Hari != nil {
		updateFields = append(updateFields, fmt.Sprintf(`hari = $%d`, argCount))
		args = append(args, *req.Hari)
		argCount++
	}

	if req.JamMulai != nil {
		jamMulai, err := time.Parse("15:04", *req.JamMulai)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"status":  "error",
				"message": "Format jam_mulai harus HH:MM",
			})
			return
		}
		updateFields = append(updateFields, fmt.Sprintf(`jam_mulai = $%d`, argCount))
		args = append(args, jamMulai)
		argCount++
	}

	if req.JamSelesai != nil {
		jamSelesai, err := time.Parse("15:04", *req.JamSelesai)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"status":  "error",
				"message": "Format jam_selesai harus HH:MM",
			})
			return
		}
		updateFields = append(updateFields, fmt.Sprintf(`jam_selesai = $%d`, argCount))
		args = append(args, jamSelesai)
		argCount++
	}

	if req.Ruang != nil {
		updateFields = append(updateFields, fmt.Sprintf(`ruang = $%d`, argCount))
		args = append(args, *req.Ruang)
		argCount++
	}

	if len(updateFields) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Tidak ada field untuk diupdate",
		})
		return
	}

	query += fmt.Sprintf(`%s WHERE id = $%d`, joinStrings(updateFields, ", "), argCount)
	args = append(args, id)

	_, err := config.DB.Exec(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal update jadwal",
			"detail":  err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Jadwal berhasil diupdate",
	})
}

// DeleteJadwal - Delete jadwal
func DeleteJadwal(c *gin.Context) {
	id := c.Param("id")

	// Delete referencing absensi records first to avoid FK constraint violation
	_, err := config.DB.Exec(context.Background(), `DELETE FROM absensi WHERE jadwal_id = $1`, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal hapus absensi terkait",
			"detail":  err.Error(),
		})
		return
	}

	result, err := config.DB.Exec(context.Background(), `DELETE FROM jadwal WHERE id = $1`, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal hapus jadwal",
			"detail":  err.Error(),
		})
		return
	}

	rowsAffected := result.RowsAffected()
	if rowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{
			"status":  "error",
			"message": "Jadwal not found",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Jadwal berhasil dihapus",
	})
}

// GetJadwalByHari - Get jadwal by hari (for students)
func GetJadwalByHari(c *gin.Context) {
	hari := c.Query("hari")

	if hari == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"status":  "error",
			"message": "Parameter hari wajib",
		})
		return
	}

	rows, err := config.DB.Query(context.Background(), `
		SELECT j.id, j.paket_id, j.mentor_id, j.class_level, j.mata_pelajaran, j.hari, to_char(j.jam_mulai, 'HH24:MI') as waktu_mulai, to_char(j.jam_selesai, 'HH24:MI') as waktu_selesai, j.ruang, COALESCE(m.nama_mentor, '') as mentor
		FROM jadwal j
		LEFT JOIN mentor m ON m.id = j.mentor_id
		WHERE j.hari = $1
		ORDER BY j.jam_mulai
	`, hari)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"status":  "error",
			"message": "Gagal fetch jadwal",
			"detail":  err.Error(),
		})
		return
	}
	defer rows.Close()

	var jadwals []models.Jadwal
	for rows.Next() {
		var j models.Jadwal
		if err := rows.Scan(
			&j.ID,
			&j.PaketID,
			&j.MentorID,
			&j.ClassLevel,
			&j.MataPelajaran,
			&j.Hari,
			&j.WaktuMulai,
			&j.WaktuSelesai,
			&j.Ruang,
			&j.Mentor,
		); err != nil {
			continue
		}
		j.JamMulai = j.WaktuMulai
		j.JamSelesai = j.WaktuSelesai
		jadwals = append(jadwals, j)
	}

	if jadwals == nil {
		jadwals = []models.Jadwal{}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Jadwal by hari fetched",
		"data":    jadwals,
		"count":   len(jadwals),
	})
}

// Helper function
func joinStrings(arr []string, sep string) string {
	if len(arr) == 0 {
		return ""
	}
	result := arr[0]
	for _, s := range arr[1:] {
		result += sep + s
	}
	return result
}
