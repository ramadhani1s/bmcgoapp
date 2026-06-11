package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"bmcgoapp-backend/config"
	"bmcgoapp-backend/services"

	"github.com/gin-gonic/gin"
)

// ==================== PAYLOAD STRUCTS ====================

type tryoutPayload struct {
	PaketID           int            `json:"paket_id"`
	MentorID          int            `json:"mentor_id"`
	ClassLevel        string         `json:"class_level"`
	Judul             string         `json:"judul"`
	Tanggal           string         `json:"tanggal"`
	Durasi            int            `json:"durasi"`
	TotalQuestions    int            `json:"total_questions"`
	CategoryQuestions map[string]int `json:"category_questions"`
}

type olimpiadePayload struct {
	MentorID          int            `json:"mentor_id"`
	ClassLevel        string         `json:"class_level"`
	Nama              string         `json:"nama"`
	Tanggal           string         `json:"tanggal"`
	Lokasi            string         `json:"lokasi"`
	Durasi            int            `json:"durasi"`
	TotalQuestions    int            `json:"total_questions"`
	CategoryQuestions map[string]int `json:"category_questions"`
}

// ==================== HELPER FUNCTIONS ====================

func getUserIDFromContext(c *gin.Context) (int, error) {
	userIDRaw, exists := c.Get("user_id")
	if !exists {
		return 0, fmt.Errorf("user_id tidak ditemukan")
	}

	userID, ok := userIDRaw.(int)
	if !ok || userID <= 0 {
		return 0, fmt.Errorf("user_id tidak valid")
	}

	return userID, nil
}

func resolveMentorID(userID int, providedMentorID int) (int, error) {
	if providedMentorID > 0 {
		return providedMentorID, nil
	}

	var mentorID int
	err := config.DB.QueryRow(context.Background(), `
		SELECT id FROM mentor WHERE user_id = $1 LIMIT 1
	`, userID).Scan(&mentorID)
	if err == nil {
		return mentorID, nil
	}

	err = config.DB.QueryRow(context.Background(), `
		SELECT id FROM mentor WHERE id = $1 LIMIT 1
	`, userID).Scan(&mentorID)
	if err == nil {
		return mentorID, nil
	}

	// Fallback/auto-creation: if the user exists and has a mentor role_id = 2, auto-create a mentor record.
	var roleID int
	var nama string
	var email string
	err = config.DB.QueryRow(context.Background(), `
		SELECT role_id, nama, COALESCE(email, username) FROM users WHERE id = $1
	`, userID).Scan(&roleID, &nama, &email)
	if err == nil && roleID == 2 {
		var newMentorID int
		err = config.DB.QueryRow(context.Background(), `
			INSERT INTO mentor (user_id, nama_mentor, mata_pelajaran, email, status)
			VALUES ($1, $2, 'Matematika', $3, 'aktif')
			RETURNING id
		`, userID, nama, email).Scan(&newMentorID)
		if err == nil {
			log.Printf("Automatically created mentor profile (ID: %d) for User ID: %d (%s)", newMentorID, userID, email)
			return newMentorID, nil
		}
	}

	return 0, fmt.Errorf("mentor untuk user_id %d tidak ditemukan", userID)
}

func resolvePaketID(providedPaketID int) (int, error) {
	if providedPaketID > 0 {
		var existingID int
		err := config.DB.QueryRow(context.Background(), `
			SELECT id FROM paket_les WHERE id = $1 LIMIT 1
		`, providedPaketID).Scan(&existingID)
		if err == nil {
			return existingID, nil
		}
	}

	var paketID int
	err := config.DB.QueryRow(context.Background(), `
		SELECT id FROM paket_les ORDER BY id ASC LIMIT 1
	`).Scan(&paketID)
	if err == nil {
		return paketID, nil
	}

	rows, err := config.DB.Query(context.Background(), `
		SELECT column_name, data_type
		FROM information_schema.columns
		WHERE table_schema = 'public'
		  AND table_name = 'paket_les'
		  AND is_nullable = 'NO'
		  AND column_default IS NULL
		  AND is_identity = 'NO'
		ORDER BY ordinal_position
	`)
	if err != nil {
		return 0, fmt.Errorf("gagal membaca struktur paket_les: %w", err)
	}
	defer rows.Close()

	columns := make([]string, 0)
	placeholders := make([]string, 0)
	args := make([]any, 0)

	for rows.Next() {
		var columnName string
		var dataType string
		if scanErr := rows.Scan(&columnName, &dataType); scanErr != nil {
			return 0, fmt.Errorf("gagal membaca metadata kolom paket_les: %w", scanErr)
		}

		lowerCol := strings.ToLower(strings.TrimSpace(columnName))
		lowerType := strings.ToLower(strings.TrimSpace(dataType))

		var value any
		switch {
		case strings.Contains(lowerCol, "nama") || strings.Contains(lowerCol, "judul") || strings.Contains(lowerCol, "title"):
			value = "Paket Default"
		case strings.Contains(lowerCol, "status"):
			value = "aktif"
		case strings.Contains(lowerCol, "harga") || strings.Contains(lowerCol, "price") || strings.Contains(lowerCol, "biaya") || strings.Contains(lowerCol, "nominal"):
			value = 0
		case strings.Contains(lowerCol, "durasi") || strings.Contains(lowerCol, "bulan") || strings.Contains(lowerCol, "hari") || strings.Contains(lowerCol, "minggu"):
			value = 1
		case strings.Contains(lowerCol, "kuota") || strings.Contains(lowerCol, "jumlah") || strings.Contains(lowerCol, "maks"):
			value = 0
		case strings.Contains(lowerType, "int") || strings.Contains(lowerType, "numeric") || strings.Contains(lowerType, "double") || strings.Contains(lowerType, "real"):
			value = 0
		case strings.Contains(lowerType, "bool"):
			value = true
		case strings.Contains(lowerType, "date") || strings.Contains(lowerType, "time"):
			value = time.Now().UTC()
		default:
			value = "-"
		}

		columns = append(columns, columnName)
		args = append(args, value)
		placeholders = append(placeholders, fmt.Sprintf("$%d", len(args)))
	}

	if rows.Err() != nil {
		return 0, fmt.Errorf("gagal membaca baris metadata paket_les: %w", rows.Err())
	}

	if len(columns) == 0 {
		err = config.DB.QueryRow(context.Background(), `
			INSERT INTO paket_les DEFAULT VALUES
			RETURNING id
		`).Scan(&paketID)
	} else {
		query := fmt.Sprintf(
			"INSERT INTO paket_les (%s) VALUES (%s) RETURNING id",
			strings.Join(columns, ", "),
			strings.Join(placeholders, ", "),
		)
		err = config.DB.QueryRow(context.Background(), query, args...).Scan(&paketID)
	}
	if err != nil {
		return 0, fmt.Errorf("gagal membuat paket default: %w", err)
	}

	return paketID, nil
}

func parseDateOrNil(dateText string) (*time.Time, error) {
	dateText = strings.TrimSpace(dateText)
	if dateText == "" {
		return nil, nil
	}

	parsed, err := time.Parse("2006-01-02", dateText)
	if err == nil {
		return &parsed, nil
	}

	parsed, err = time.Parse("02/01/2006", dateText)
	if err == nil {
		return &parsed, nil
	}

	return nil, fmt.Errorf("format tanggal harus YYYY-MM-DD atau DD/MM/YYYY")
}

func formatDate(t *time.Time) string {
	if t == nil {
		return ""
	}
	return t.Format("2006-01-02")
}
// ==================== TRYOUT HANDLERS ====================

func GetTryoutHandler(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	mentorID, err := resolveMentorID(userID, 0)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	rows, err := config.DB.Query(context.Background(), `
		SELECT id, paket_id, mentor_id, class_level, judul, tanggal, durasi, total_questions, category_questions,
		       COALESCE((SELECT COUNT(*) FROM tryout_soal WHERE kompetisi_id = tryout.id), 0) as soal_terbuat
		FROM tryout
		WHERE mentor_id = $1
		ORDER BY id DESC
	`, mentorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	items := make([]gin.H, 0)
	for rows.Next() {
		var id, paketID, mentorIDRow, durasi, totalQuestions, soalTerbuat int
		var classLevel string
		var judul string
		var tanggal *time.Time
		var categoryQuestions []byte

		if err := rows.Scan(&id, &paketID, &mentorIDRow, &classLevel, &judul, &tanggal, &durasi, &totalQuestions, &categoryQuestions, &soalTerbuat); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		catData := gin.H{}
		if len(categoryQuestions) > 0 {
			_ = json.Unmarshal(categoryQuestions, &catData)
		}

		items = append(items, gin.H{
			"id":                 id,
			"paket_id":           paketID,
			"mentor_id":          mentorIDRow,
			"class_level":        classLevel,
			"judul":              judul,
			"tanggal":            formatDate(tanggal),
			"durasi":             durasi,
			"total_questions":    totalQuestions,
			"soal_terbuat":       soalTerbuat,
			"category_questions": catData,
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": items})
}

func CreateTryoutHandler(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	var payload tryoutPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "request tidak valid", "details": err.Error()})
		return
	}

	paketID, err := resolvePaketID(payload.PaketID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	mentorID, err := resolveMentorID(userID, payload.MentorID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tanggal, err := parseDateOrNil(payload.Tanggal)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	categoryQuestionsJSON, err := json.Marshal(payload.CategoryQuestions)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "category_questions format tidak valid"})
		return
	}

	var id int
	err = config.DB.QueryRow(context.Background(), `
		INSERT INTO tryout (paket_id, mentor_id, class_level, judul, tanggal, durasi, total_questions, category_questions)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id
	`, paketID, mentorID, payload.ClassLevel, payload.Judul, tanggal, payload.Durasi, payload.TotalQuestions, categoryQuestionsJSON).Scan(&id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Kirim Notifikasi FCM ke semua siswa secara asinkron
	go func(judul string) {
		rows, err := config.DB.Query(context.Background(), `SELECT fcm_token FROM users WHERE role_id = 3 AND fcm_token IS NOT NULL AND fcm_token != ''`)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var token string
				if err := rows.Scan(&token); err == nil && token != "" {
					_ = services.SendFCMNotification(token, "Try Out Baru Tersedia! 📝", fmt.Sprintf("Try Out '%s' telah ditambahkan. Yuk kerjakan sekarang!", judul))
				}
			}
		}
	}(payload.Judul)

	c.JSON(http.StatusCreated, gin.H{
		"message": "Tryout berhasil dibuat",
		"id":      id,
	})
}

func UpdateTryoutHandler(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	tryoutID, err := strconv.Atoi(c.Param("id"))
	if err != nil || tryoutID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id tryout tidak valid"})
		return
	}

	var payload tryoutPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "request tidak valid", "details": err.Error()})
		return
	}

	mentorID, err := resolveMentorID(userID, payload.MentorID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	paketID, err := resolvePaketID(payload.PaketID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tanggal, err := parseDateOrNil(payload.Tanggal)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	categoryQuestionsJSON, err := json.Marshal(payload.CategoryQuestions)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "category_questions format tidak valid"})
		return
	}

	cmd, err := config.DB.Exec(context.Background(), `
		UPDATE tryout
		SET paket_id = $1,
		    class_level = $2,
		    judul = $3,
		    tanggal = $4,
		    durasi = $5,
		    total_questions = $6,
		    category_questions = $7
		WHERE id = $8 AND mentor_id = $9
	`, paketID, payload.ClassLevel, payload.Judul, tanggal, payload.Durasi, payload.TotalQuestions, categoryQuestionsJSON, tryoutID, mentorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if cmd.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tryout tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Tryout berhasil diupdate"})
}

func DeleteTryoutHandler(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	tryoutID, err := strconv.Atoi(c.Param("id"))
	if err != nil || tryoutID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id tryout tidak valid"})
		return
	}

	mentorID, err := resolveMentorID(userID, 0)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Delete related records first to avoid foreign key constraints
	_, _ = config.DB.Exec(context.Background(), `DELETE FROM hasil_tryout WHERE tryout_id = $1`, tryoutID)
	_, _ = config.DB.Exec(context.Background(), `DELETE FROM tryout_soal WHERE kompetisi_id = $1`, tryoutID)

	cmd, err := config.DB.Exec(context.Background(), `
		DELETE FROM tryout WHERE id = $1 AND mentor_id = $2
	`, tryoutID, mentorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if cmd.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tryout tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Tryout berhasil dihapus"})
}
// ==================== OLIMPIADE HANDLERS (DIPERBAIKI) ====================

func GetOlimpiadeHandler(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	mentorID, err := resolveMentorID(userID, 0)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	rows, err := config.DB.Query(context.Background(), `
		SELECT id, mentor_id, class_level, nama, tanggal, lokasi, total_questions, category_questions,
		       COALESCE((SELECT COUNT(*) FROM olimpiade_soal WHERE kompetisi_id = olimpiade.id), 0) as soal_terbuat
		FROM olimpiade
		WHERE mentor_id = $1
		ORDER BY id DESC
	`, mentorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	items := make([]gin.H, 0)
	for rows.Next() {
		var id, mentorIDRow, totalQuestions, soalTerbuat int
		var classLevel, nama, lokasi string
		var tanggal *time.Time
		var categoryQuestions []byte

		if err := rows.Scan(&id, &mentorIDRow, &classLevel, &nama, &tanggal, &lokasi, &totalQuestions, &categoryQuestions, &soalTerbuat); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		catData := gin.H{}
		if len(categoryQuestions) > 0 {
			_ = json.Unmarshal(categoryQuestions, &catData)
		}

		items = append(items, gin.H{
			"id":                 id,
			"mentor_id":          mentorIDRow,
			"class_level":        classLevel,
			"nama":               nama,
			"tanggal":            formatDate(tanggal),
			"lokasi":             lokasi,
			"total_questions":    totalQuestions,
			"soal_terbuat":       soalTerbuat,
			"category_questions": catData,
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": items})
}

func CreateOlimpiadeHandler(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	var payload olimpiadePayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "request tidak valid", "details": err.Error()})
		return
	}

	mentorID, err := resolveMentorID(userID, payload.MentorID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tanggal, err := parseDateOrNil(payload.Tanggal)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 🔥 PERBAIKAN: Ubah category_questions ke JSON
	categoryQuestionsJSON, err := json.Marshal(payload.CategoryQuestions)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "category_questions format tidak valid"})
		return
	}

	// INSERT dengan durasi, total_questions dan category_questions
	var id int
	durasiFinal := payload.Durasi
	if durasiFinal <= 0 {
		durasiFinal = 120 // default 120 menit
	}
	err = config.DB.QueryRow(context.Background(), `
		INSERT INTO olimpiade (mentor_id, class_level, nama, tanggal, lokasi, durasi, total_questions, category_questions)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id
	`, mentorID, payload.ClassLevel, payload.Nama, tanggal, payload.Lokasi, durasiFinal, payload.TotalQuestions, categoryQuestionsJSON).Scan(&id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Olimpiade berhasil dibuat",
		"id":      id,
		"data": gin.H{
			"id":                 id,
			"mentor_id":          mentorID,
			"class_level":        payload.ClassLevel,
			"nama":               payload.Nama,
			"tanggal":            formatDate(tanggal),
			"lokasi":             payload.Lokasi,
			"durasi":             durasiFinal,
			"total_questions":    payload.TotalQuestions,
			"category_questions": payload.CategoryQuestions,
		},
	})

	// Kirim Notifikasi FCM ke semua siswa secara asinkron
	go func(nama string) {
		rows, err := config.DB.Query(context.Background(), `SELECT fcm_token FROM users WHERE role_id = 3 AND fcm_token IS NOT NULL AND fcm_token != ''`)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var token string
				if err := rows.Scan(&token); err == nil && token != "" {
					_ = services.SendFCMNotification(token, "Olimpiade Baru! 🏆", fmt.Sprintf("Olimpiade '%s' telah ditambahkan. Cek sekarang!", nama))
				}
			}
		}
	}(payload.Nama)
}

func UpdateOlimpiadeHandler(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	olimpiadeID, err := strconv.Atoi(c.Param("id"))
	if err != nil || olimpiadeID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id olimpiade tidak valid"})
		return
	}

	var payload olimpiadePayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "request tidak valid", "details": err.Error()})
		return
	}

	mentorID, err := resolveMentorID(userID, payload.MentorID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tanggal, err := parseDateOrNil(payload.Tanggal)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 🔥 PERBAIKAN: Ubah category_questions ke JSON
	categoryQuestionsJSON, err := json.Marshal(payload.CategoryQuestions)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "category_questions format tidak valid"})
		return
	}

	// UPDATE dengan durasi, total_questions dan category_questions
	durasiFinalUpd := payload.Durasi
	if durasiFinalUpd <= 0 {
		durasiFinalUpd = 120
	}
	cmd, err := config.DB.Exec(context.Background(), `
		UPDATE olimpiade
		SET class_level = $1,
		    nama = $2,
		    tanggal = $3,
		    lokasi = $4,
		    durasi = $5,
		    total_questions = $6,
		    category_questions = $7
		WHERE id = $8 AND mentor_id = $9
	`, payload.ClassLevel, payload.Nama, tanggal, payload.Lokasi, durasiFinalUpd, payload.TotalQuestions, categoryQuestionsJSON, olimpiadeID, mentorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if cmd.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Olimpiade tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Olimpiade berhasil diupdate"})
}

func DeleteOlimpiadeHandler(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	olimpiadeID, err := strconv.Atoi(c.Param("id"))
	if err != nil || olimpiadeID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id olimpiade tidak valid"})
		return
	}

	mentorID, err := resolveMentorID(userID, 0)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Delete related records first to avoid foreign key constraints
	_, _ = config.DB.Exec(context.Background(), `DELETE FROM peserta_olimpiade WHERE olimpiade_id = $1`, olimpiadeID)
	_, _ = config.DB.Exec(context.Background(), `DELETE FROM hasil_olimpiade WHERE olimpiade_id = $1`, olimpiadeID)
	_, _ = config.DB.Exec(context.Background(), `DELETE FROM olimpiade_soal WHERE kompetisi_id = $1`, olimpiadeID)

	cmd, err := config.DB.Exec(context.Background(), `
		DELETE FROM olimpiade WHERE id = $1 AND mentor_id = $2
	`, olimpiadeID, mentorID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if cmd.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Olimpiade tidak ditemukan"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Olimpiade berhasil dihapus"})
}

// ==================== PESERTA OLIMPIADE HANDLERS ====================

func GetPesertaOlimpiadeHandler(c *gin.Context) {
	olimpiadeID, err := strconv.Atoi(c.Param("id"))
	if err != nil || olimpiadeID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id olimpiade tidak valid"})
		return
	}

	rows, err := config.DB.Query(context.Background(), `
		SELECT id, siswa_id, olimpiade_id
		FROM peserta_olimpiade
		WHERE olimpiade_id = $1
		ORDER BY id DESC
	`, olimpiadeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	items := make([]gin.H, 0)
	for rows.Next() {
		var id, siswaID, olimpiadeIDRow int
		if err := rows.Scan(&id, &siswaID, &olimpiadeIDRow); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		items = append(items, gin.H{
			"id":           id,
			"siswa_id":     siswaID,
			"olimpiade_id": olimpiadeIDRow,
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": items})
}

func CreatePesertaOlimpiadeHandler(c *gin.Context) {
	olimpiadeID, err := strconv.Atoi(c.Param("id"))
	if err != nil || olimpiadeID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id olimpiade tidak valid"})
		return
	}

	var payload struct {
		SiswaID int `json:"siswa_id"`
	}

	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "request tidak valid", "details": err.Error()})
		return
	}

	if payload.SiswaID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "siswa_id wajib diisi"})
		return
	}

	var id int
	err = config.DB.QueryRow(context.Background(), `
		INSERT INTO peserta_olimpiade (siswa_id, olimpiade_id)
		VALUES ($1, $2)
		RETURNING id
	`, payload.SiswaID, olimpiadeID).Scan(&id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Peserta olimpiade berhasil ditambahkan", "id": id})
}

// ==================== HASIL TRYOUT HANDLERS ====================

func GetHasilTryoutByTryoutHandler(c *gin.Context) {
	tryoutID, err := strconv.Atoi(c.Param("id"))
	if err != nil || tryoutID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id tryout tidak valid"})
		return
	}

	rows, err := config.DB.Query(context.Background(), `
		SELECT ht.id, ht.siswa_id, ht.tryout_id, ht.nilai,
		       COALESCE(s.nama, u.nama, 'Siswa') AS nama_siswa
		FROM hasil_tryout ht
		LEFT JOIN siswa s ON s.id = ht.siswa_id
		LEFT JOIN users u ON u.id = s.user_id
		WHERE ht.tryout_id = $1
		ORDER BY ht.nilai DESC
	`, tryoutID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	items := make([]gin.H, 0)
	for rows.Next() {
		var id, siswaID, tryoutIDRow, nilai int
		var namaSiswa string
		if err := rows.Scan(&id, &siswaID, &tryoutIDRow, &nilai, &namaSiswa); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		items = append(items, gin.H{
			"id":          id,
			"siswa_id":    siswaID,
			"tryout_id":   tryoutIDRow,
			"nilai":       nilai,
			"nama_siswa":  namaSiswa,
			"status":      "selesai",
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": items})
}

func CreateHasilTryoutHandler(c *gin.Context) {
	tryoutID, err := strconv.Atoi(c.Param("id"))
	if err != nil || tryoutID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id tryout tidak valid"})
		return
	}

	var payload struct {
		SiswaID int `json:"siswa_id"`
		Nilai   int `json:"nilai"`
	}

	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "request tidak valid", "details": err.Error()})
		return
	}

	if payload.SiswaID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "siswa_id wajib diisi"})
		return
	}

	var id int
	err = config.DB.QueryRow(context.Background(), `
		INSERT INTO hasil_tryout (siswa_id, tryout_id, nilai)
		VALUES ($1, $2, $3)
		RETURNING id
	`, payload.SiswaID, tryoutID, payload.Nilai).Scan(&id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Hasil tryout berhasil dibuat", "id": id})
}

// ==================== EVALUASI HANDLERS ====================

func GetEvaluasiHandler(c *gin.Context) {
	siswaIDParam := c.Query("siswa_id")
	query := `SELECT id, siswa_id, nilai, catatan FROM evaluasi`
	args := make([]any, 0)
	if siswaIDParam != "" {
		siswaID, err := strconv.Atoi(siswaIDParam)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "siswa_id tidak valid"})
			return
		}
		query += ` WHERE siswa_id = $1`
		args = append(args, siswaID)
	}
	query += ` ORDER BY id DESC`

	rows, err := config.DB.Query(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	items := make([]gin.H, 0)
	for rows.Next() {
		var id, siswaID, nilai int
		var catatan string
		if err := rows.Scan(&id, &siswaID, &nilai, &catatan); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		items = append(items, gin.H{
			"id":       id,
			"siswa_id": siswaID,
			"nilai":    nilai,
			"catatan":  catatan,
		})
	}

	c.JSON(http.StatusOK, gin.H{"data": items})
}

func CreateEvaluasiHandler(c *gin.Context) {
	var payload struct {
		SiswaID int    `json:"siswa_id"`
		Nilai   int    `json:"nilai"`
		Catatan string `json:"catatan"`
	}

	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "request tidak valid", "details": err.Error()})
		return
	}

	if payload.SiswaID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "siswa_id wajib diisi"})
		return
	}

	var id int
	err := config.DB.QueryRow(context.Background(), `
		INSERT INTO evaluasi (siswa_id, nilai, catatan)
		VALUES ($1, $2, $3)
		RETURNING id
	`, payload.SiswaID, payload.Nilai, payload.Catatan).Scan(&id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Evaluasi berhasil dibuat", "id": id})
}