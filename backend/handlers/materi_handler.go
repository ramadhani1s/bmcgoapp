package handlers

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
)

// Constanta untuk upload
const MaxUploadSize = 15 << 20 // 15 MB
var AllowedExtensions = map[string]bool{
	".pdf":  true,
	".pptx": true,
	".ppt":  true,
	".docx": true,
	".doc":  true,
}

func UploadMateri(c *gin.Context) {
	// Dapatkan ID Mentor dari context auth (sementara kita asumsikan dikirim via form data jika belum ada middleware JWT ketat untuk mentor, tapi sebaiknya dari claims JWT)
	// Untuk keamanan, di sini kita ambil dari form "mentor_id" sebagai fallback jika JWT belum diimplementasi penuh untuk mentor.
	mentorIDStr := c.PostForm("mentor_id")
	if mentorIDStr == "" {
		// Coba ambil dari claims JWT (asumsi "user_id")
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized: mentor_id required"})
			return
		}
		// Di sini idealnya query ke DB untuk dapat mentor_id dari user_id.
		// Untuk kemudahan dan sesuai struktur saat ini, kita gunakan user_id sebagai mentor_id (jika mereka sama di tabel mentor)
		mentorIDStr = fmt.Sprintf("%v", userID)
	}

	mentorID, err := strconv.Atoi(mentorIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mentor_id parameter"})
		return
	}

	// Resolve actual mentor_id from DB
	var actualMentorID int
	err = config.DB.QueryRow(context.Background(), `
		SELECT id FROM mentor WHERE user_id = $1 LIMIT 1
	`, mentorID).Scan(&actualMentorID)
	
	if err != nil {
		err = config.DB.QueryRow(context.Background(), `
			SELECT id FROM mentor WHERE id = $1 LIMIT 1
		`, mentorID).Scan(&actualMentorID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Mentor not found"})
			return
		}
	}
	mentorID = actualMentorID

	title := c.PostForm("title")
	if title == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Title is required"})
		return
	}
	description := c.PostForm("description")
	subject := c.PostForm("subject")
	if subject == "" {
		subject = "Umum" // Default subject jika tidak dikirim
	}

	// Limit upload size
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, MaxUploadSize)

	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File size exceeds 15MB or no file uploaded"})
		return
	}

	// Validasi ekstensi
	ext := strings.ToLower(filepath.Ext(file.Filename))
	if !AllowedExtensions[ext] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file type. Only PDF, PPTX, PPT, DOCX, DOC allowed."})
		return
	}

	// Buat direktori jika belum ada
	uploadDir := "./uploads/materials"
	if err := os.MkdirAll(uploadDir, os.ModePerm); err != nil {
		log.Println("Gagal membuat direktori upload:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upload directory"})
		return
	}

	// Generate nama file unik
	filename := fmt.Sprintf("%d_%d%s", mentorID, time.Now().UnixNano(), ext)
	dst := filepath.Join(uploadDir, filename)

	// Simpan file
	if err := c.SaveUploadedFile(file, dst); err != nil {
		log.Println("Gagal menyimpan file:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}

	// Simpan ke DB
	filePathDB := "/uploads/materials/" + filename
	var insertedID int
	err = config.DB.QueryRow(context.Background(), `
		INSERT INTO learning_materials (mentor_id, title, description, file_path, file_type, file_size, subject)
		VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id
	`, mentorID, title, description, filePathDB, ext, file.Size, subject).Scan(&insertedID)

	if err != nil {
		log.Println("Gagal insert learning_materials ke DB:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save to database"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "File uploaded successfully",
		"data": gin.H{
			"id":        insertedID,
			"file_path": filePathDB,
		},
	})
}

func GetMateriByMentor(c *gin.Context) {
	mentorIDStr := c.Query("mentor_id")
	if mentorIDStr == "" {
		// Fallback to JWT claims
		userID, exists := c.Get("user_id")
		if exists {
			mentorIDStr = fmt.Sprintf("%v", userID)
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"error": "mentor_id is required"})
			return
		}
	}

	mentorID, err := strconv.Atoi(mentorIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mentor_id parameter"})
		return
	}

	// Resolve actual mentor_id from DB
	var actualMentorID int
	err = config.DB.QueryRow(context.Background(), `
		SELECT id FROM mentor WHERE user_id = $1 LIMIT 1
	`, mentorID).Scan(&actualMentorID)
	
	if err != nil {
		err = config.DB.QueryRow(context.Background(), `
			SELECT id FROM mentor WHERE id = $1 LIMIT 1
		`, mentorID).Scan(&actualMentorID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Mentor not found"})
			return
		}
	}
	mentorID = actualMentorID

	rows, err := config.DB.Query(context.Background(), `
		SELECT id, mentor_id, title, description, file_path, file_type, file_size, subject, created_at, updated_at
		FROM learning_materials
		WHERE mentor_id = $1
		ORDER BY created_at DESC
	`, mentorID)

	if err != nil {
		log.Println("Gagal query learning_materials:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch materials"})
		return
	}
	defer rows.Close()

	var materials []models.MateriPembelajaran
	for rows.Next() {
		var m models.MateriPembelajaran
		if err := rows.Scan(&m.ID, &m.MentorID, &m.Title, &m.Description, &m.FilePath, &m.FileType, &m.FileSize, &m.Subject, &m.CreatedAt, &m.UpdatedAt); err != nil {
			log.Println("Gagal scan row:", err)
			continue
		}
		materials = append(materials, m)
	}

	c.JSON(http.StatusOK, materials)
}

func DeleteMateri(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	// Dapatkan file_path dari DB untuk dihapus fisiknya
	var filePath string
	err = config.DB.QueryRow(context.Background(), "SELECT file_path FROM learning_materials WHERE id = $1", id).Scan(&filePath)
	if err != nil {
		log.Println("Gagal get filepath:", err)
		c.JSON(http.StatusNotFound, gin.H{"error": "Material not found"})
		return
	}

	// Hapus record dari DB
	_, err = config.DB.Exec(context.Background(), "DELETE FROM learning_materials WHERE id = $1", id)
	if err != nil {
		log.Println("Gagal delete dari db:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete from database"})
		return
	}

	// Hapus file fisik (filePath biasanya diawali "/uploads/...")
	// Perlu ubah agar sesuai dengan directory local "./uploads/..."
	localPath := "." + filePath
	if err := os.Remove(localPath); err != nil {
		log.Println("Warning: Gagal hapus file fisik:", err)
		// Tidak mereturn error ke user karena db sudah dihapus
	}

	c.JSON(http.StatusOK, gin.H{"message": "Material deleted successfully"})
}
func GetAllMateri(c *gin.Context) {
	subject := c.Query("subject")

	var rows pgx.Rows
	var err error

	if subject != "" && subject != "Semua" {
		rows, err = config.DB.Query(context.Background(), `
			SELECT 
				lm.id, lm.mentor_id, lm.title, lm.description, 
				lm.file_path, lm.file_type, lm.file_size, lm.subject,
				COALESCE(m.nama, u.nama, 'Mentor') AS mentor_name,
				lm.created_at, lm.updated_at
			FROM learning_materials lm
			LEFT JOIN mentor m ON m.id = lm.mentor_id
			LEFT JOIN users u ON u.id = m.user_id
			WHERE lm.subject = $1
			ORDER BY lm.created_at DESC
		`, subject)
	} else {
		rows, err = config.DB.Query(context.Background(), `
			SELECT 
				lm.id, lm.mentor_id, lm.title, lm.description, 
				lm.file_path, lm.file_type, lm.file_size, lm.subject,
				COALESCE(m.nama, u.nama, 'Mentor') AS mentor_name,
				lm.created_at, lm.updated_at
			FROM learning_materials lm
			LEFT JOIN mentor m ON m.id = lm.mentor_id
			LEFT JOIN users u ON u.id = m.user_id
			ORDER BY lm.created_at DESC
		`)
	}

	if err != nil {
		log.Println("Gagal query semua materi:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil materi"})
		return
	}
	defer rows.Close()

	type MateriWithMentor struct {
		ID          int       `json:"id"`
		MentorID    int       `json:"mentor_id"`
		Title       string    `json:"title"`
		Description string    `json:"description"`
		FilePath    string    `json:"file_path"`
		FileType    string    `json:"file_type"`
		FileSize    int64     `json:"file_size"`
		Subject     string    `json:"subject"`
		MentorName  string    `json:"mentor_name"`
		CreatedAt   time.Time `json:"created_at"`
		UpdatedAt   time.Time `json:"updated_at"`
	}

	var materials []MateriWithMentor
	for rows.Next() {
		var m MateriWithMentor
		if err := rows.Scan(
			&m.ID, &m.MentorID, &m.Title, &m.Description,
			&m.FilePath, &m.FileType, &m.FileSize, &m.Subject,
			&m.MentorName, &m.CreatedAt, &m.UpdatedAt,
		); err != nil {
			log.Println("Gagal scan row:", err)
			continue
		}
		materials = append(materials, m)
	}

	if materials == nil {
		materials = []MateriWithMentor{}
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Berhasil mengambil materi",
		"data":    materials,
	})
}
