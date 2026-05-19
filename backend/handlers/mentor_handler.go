package handlers

import (
	"context"
	"strings"

	"bmcgoapp-backend/config"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

// ===============================
// GET ALL MENTOR
// ===============================
func GetMentors(c *gin.Context) {
	rows, err := config.DB.Query(context.Background(), `
		SELECT 
			id,
			nama,
			COALESCE(email, ''),
			COALESCE(password, ''),
			COALESCE(mata_pelajaran, ''),
			COALESCE(status, 'Aktif')
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

	userStatus := "aktif"
	if strings.EqualFold(input.Status, "nonaktif") {
		userStatus = "nonaktif"
	}

	// First, ensure there is a corresponding user record so mentor can login.
	// If the email already exists as a siswa/admin account, promote it to mentor.
	var userID int
	var existingUserPassword string
	lookupErr := config.DB.QueryRow(context.Background(), `
		SELECT id, COALESCE(password, '')
		FROM users
		WHERE LOWER(COALESCE(NULLIF(email, ''), username)) = LOWER($1)
		LIMIT 1
	`, input.Email).Scan(&userID, &existingUserPassword)

	hashed, hashErr := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if hashErr != nil {
		c.JSON(500, gin.H{"error": "gagal hash password"})
		return
	}

	if lookupErr != nil {
		insert := `
			INSERT INTO users (nama, username, email, password, role_id, status)
			VALUES ($1,$2,$3,$4,$5,$6)
			RETURNING id
		`
		insertErr := config.DB.QueryRow(context.Background(), insert, input.NamaMentor, input.Email, input.Email, string(hashed), 2, userStatus).Scan(&userID)
		if insertErr != nil {
			c.JSON(500, gin.H{"error": insertErr.Error()})
			return
		}
	} else {
		// Update existing user row so the mentor gets proper mentor privileges.
		_, updateErr := config.DB.Exec(context.Background(), `
			UPDATE users
			SET nama = $1,
			    username = $2,
			    email = $3,
			    password = $4,
			    role_id = 2,
			    status = $5
			WHERE id = $6
		`, input.NamaMentor, input.Email, input.Email, string(hashed), userStatus, userID)
		if updateErr != nil {
			c.JSON(500, gin.H{"error": updateErr.Error()})
			return
		}
	}

	// Upsert mentor row so existing mentor accounts can be promoted without duplicate errors.
	_, mentorErr := config.DB.Exec(context.Background(), `
		INSERT INTO mentor
		(
			user_id,
			nama,
			email,
			password,
			mata_pelajaran,
			status
		)
		VALUES ($1,$2,$3,$4,$5,$6)
		ON CONFLICT (user_id)
		DO UPDATE SET
			nama_mentor = EXCLUDED.nama_mentor,
			email = EXCLUDED.email,
			password = EXCLUDED.password,
			mata_pelajaran = EXCLUDED.mata_pelajaran,
			status = EXCLUDED.status
	`,
		userID,
		input.NamaMentor,
		input.Email,
		input.Password,
		input.MataPelajaran,
		input.Status,
	)

	if mentorErr != nil {
		c.JSON(500, gin.H{"error": mentorErr.Error()})
		return
	}

	c.JSON(200, gin.H{"success": true, "message": "Mentor berhasil ditambahkan"})
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

	input.NamaMentor = strings.TrimSpace(input.NamaMentor)
	input.Email = strings.TrimSpace(input.Email)
	input.Password = strings.TrimSpace(input.Password)
	input.MataPelajaran = strings.TrimSpace(input.MataPelajaran)
	input.Status = strings.TrimSpace(input.Status)

	if input.NamaMentor == "" || input.Email == "" || input.MataPelajaran == "" {
		c.JSON(400, gin.H{"error": "Nama, email, dan mata pelajaran wajib diisi"})
		return
	}

	if input.Status == "" {
		input.Status = "Aktif"
	}

	userStatus := "aktif"
	if strings.EqualFold(input.Status, "nonaktif") {
		userStatus = "nonaktif"
	}

	var (
		mentorID int
		userID   int
	)

	err := config.DB.QueryRow(context.Background(), `
		SELECT id, user_id
		FROM mentor
		WHERE id = $1
		LIMIT 1
	`, id).Scan(&mentorID, &userID)
	if err != nil {
		c.JSON(404, gin.H{"error": "Mentor tidak ditemukan"})
		return
	}

	// kalau password diisi → update password juga
	if strings.TrimSpace(input.Password) != "" {
		hashed, hashErr := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
		if hashErr != nil {
			c.JSON(500, gin.H{"error": "gagal hash password"})
			return
		}

		_, err := config.DB.Exec(context.Background(), `
			UPDATE mentor
			SET nama=$1,
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
			mentorID,
		)

		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}

		_, err = config.DB.Exec(context.Background(), `
			UPDATE users
			SET nama=$1,
				username=$2,
				email=$3,
				password=$4,
				role_id=2,
				status=$5
			WHERE id=$6
		`,
			input.NamaMentor,
			input.Email,
			input.Email,
			string(hashed),
			userStatus,
			userID,
		)

		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}

	} else {

		_, err := config.DB.Exec(context.Background(), `
			UPDATE mentor
			SET nama=$1,
				email=$2,
				mata_pelajaran=$3,
				status=$4
			WHERE id=$5
		`,
			input.NamaMentor,
			input.Email,
			input.MataPelajaran,
			input.Status,
			mentorID,
		)

		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}

		_, err = config.DB.Exec(context.Background(), `
			UPDATE users
			SET nama=$1,
				username=$2,
				email=$3,
				role_id=2,
				status=$4
			WHERE id=$5
		`,
			input.NamaMentor,
			input.Email,
			input.Email,
			userStatus,
			userID,
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
// DELETE MENTOR (Soft Delete - set status to Nonaktif)
// ===============================
func DeleteMentor(c *gin.Context) {
	id := c.Param("id")

	var userID int
	err := config.DB.QueryRow(
		context.Background(),
		`SELECT user_id FROM mentor WHERE id=$1`,
		id,
	).Scan(&userID)

	if err != nil {
		c.JSON(404, gin.H{
			"error": "mentor tidak ditemukan",
		})
		return
	}

	_, err = config.DB.Exec(
		context.Background(),
		`UPDATE mentor SET status='Nonaktif' WHERE id=$1`,
		id,
	)

	if err != nil {
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	_, err = config.DB.Exec(
		context.Background(),
		`UPDATE users SET status='nonaktif', role_id=2 WHERE id=$1`,
		userID,
	)

	if err != nil {
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"message": "Mentor berhasil dinonaktifkan",
	})
}

// ===============================
// HARD DELETE MENTOR (Permanent)
// ===============================
func HardDeleteMentor(c *gin.Context) {
	id := c.Param("id")

	// Start transaction to delete mentor and related records
	tx, err := config.DB.Begin(context.Background())
	if err != nil {
		c.JSON(500, gin.H{
			"error": "gagal memulai transaksi: " + err.Error(),
		})
		return
	}
	defer tx.Rollback(context.Background())

	// Get mentor data to find user_id
	var userID int
	err = tx.QueryRow(
		context.Background(),
		`SELECT user_id FROM mentor WHERE id = $1`,
		id,
	).Scan(&userID)

	if err != nil {
		c.JSON(404, gin.H{
			"error": "mentor tidak ditemukan",
		})
		return
	}

	// Delete mentor record
	_, err = tx.Exec(
		context.Background(),
		`DELETE FROM mentor WHERE id=$1`,
		id,
	)
	if err != nil {
		c.JSON(500, gin.H{
			"error": "gagal menghapus mentor: " + err.Error(),
		})
		return
	}

	// Delete user record if no other roles use it
	_, err = tx.Exec(
		context.Background(),
		`DELETE FROM users WHERE id=$1`,
		userID,
	)
	if err != nil {
		c.JSON(500, gin.H{
			"error": "gagal menghapus user: " + err.Error(),
		})
		return
	}

	// Commit transaction
	err = tx.Commit(context.Background())
	if err != nil {
		c.JSON(500, gin.H{
			"error": "gagal commit transaksi: " + err.Error(),
		})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"message": "Mentor berhasil dihapus permanen",
	})
}

// ===============================
// EXPORT MENTOR TO EXCEL
// ===============================
func ExportMentorExcel(c *gin.Context) {
	rows, err := config.DB.Query(context.Background(), `
		SELECT 
			id,
			nama,
			COALESCE(email, ''),
			COALESCE(mata_pelajaran, ''),
			COALESCE(status, 'Aktif')
		FROM mentor
		ORDER BY id ASC
	`)
	if err != nil {
		c.JSON(500, gin.H{
			"error": "Gagal mengambil data mentor",
		})
		return
	}
	defer rows.Close()

	var mentors []map[string]interface{}

	for rows.Next() {
		var (
			id            int
			nama          string
			email         string
			mataPelajaran string
			status        string
		)

		err := rows.Scan(&id, &nama, &email, &mataPelajaran, &status)
		if err != nil {
			continue
		}

		mentors = append(mentors, map[string]interface{}{
			"ID":             id,
			"Nama Mentor":    nama,
			"Email":          email,
			"Mata Pelajaran": mataPelajaran,
			"Status":         status,
		})
	}

	// Return data as JSON for frontend to generate Excel
	c.Header("Content-Disposition", "attachment; filename=mentor_data.xlsx")
	c.JSON(200, gin.H{
		"success": true,
		"data":    mentors,
	})
}
