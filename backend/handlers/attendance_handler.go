package handlers

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"bmcgoapp-backend/config"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jung-kurt/gofpdf/v2"
)

const attendanceTokenChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

func generateAttendanceToken(length int) (string, error) {
	if length <= 0 {
		length = 6
	}

	b := make([]byte, length)
	for i := range b {
		random := make([]byte, 1)
		if _, err := rand.Read(random); err != nil {
			return "", err
		}
		b[i] = attendanceTokenChars[int(random[0])%len(attendanceTokenChars)]
	}

	return string(b), nil
}

func resolveMentorDatabaseID(userID int) (int, error) {
	var mentorID int
	err := config.DB.QueryRow(
		context.Background(),
		`SELECT id FROM mentor WHERE user_id = $1 LIMIT 1`,
		userID,
	).Scan(&mentorID)
	if err == nil {
		return mentorID, nil
	}

	err = config.DB.QueryRow(
		context.Background(),
		`SELECT id FROM mentor WHERE id = $1 LIMIT 1`,
		userID,
	).Scan(&mentorID)
	if err == nil {
		return mentorID, nil
	}

	return 0, fmt.Errorf("mentor tidak ditemukan")
}

func resolveSiswaDatabaseID(userID int) (int, error) {
	var siswaID int
	err := config.DB.QueryRow(
		context.Background(),
		`SELECT id FROM siswa WHERE user_id = $1 LIMIT 1`,
		userID,
	).Scan(&siswaID)
	if err == nil {
		return siswaID, nil
	}

	err = config.DB.QueryRow(
		context.Background(),
		`SELECT id FROM siswa WHERE id = $1 LIMIT 1`,
		userID,
	).Scan(&siswaID)
	if err == nil {
		return siswaID, nil
	}

	return 0, fmt.Errorf("siswa tidak ditemukan")
}

func resolveJadwalIDForAttendance(mentorUserID int, subject string, className string) (int, error) {
	mentorID, err := resolveMentorDatabaseID(mentorUserID)
	if err != nil {
		return 0, err
	}

	trimmedSubject := strings.TrimSpace(subject)
	trimmedClass := strings.TrimSpace(className)

	// Try matching both subject and class_level
	if trimmedSubject != "" && trimmedClass != "" {
		var jadwalID int
		err = config.DB.QueryRow(
			context.Background(),
			`SELECT id
			 FROM jadwal
			 WHERE mentor_id = $1
			   AND LOWER(COALESCE(mata_pelajaran, '')) = LOWER($2)
			   AND LOWER(COALESCE(class_level, '')) = LOWER($3)
			 ORDER BY id DESC
			 LIMIT 1`,
			mentorID,
			trimmedSubject,
			trimmedClass,
		).Scan(&jadwalID)
		if err == nil {
			return jadwalID, nil
		}
	}

	// Fallback 1: match subject only
	if trimmedSubject != "" {
		var jadwalID int
		err = config.DB.QueryRow(
			context.Background(),
			`SELECT id
			 FROM jadwal
			 WHERE mentor_id = $1
			   AND LOWER(COALESCE(mata_pelajaran, '')) = LOWER($2)
			 ORDER BY id DESC
			 LIMIT 1`,
			mentorID,
			trimmedSubject,
		).Scan(&jadwalID)
		if err == nil {
			return jadwalID, nil
		}
	}

	// Fallback 2: match class only
	if trimmedClass != "" {
		var jadwalID int
		err = config.DB.QueryRow(
			context.Background(),
			`SELECT id
			 FROM jadwal
			 WHERE mentor_id = $1
			   AND LOWER(COALESCE(class_level, '')) = LOWER($2)
			 ORDER BY id DESC
			 LIMIT 1`,
			mentorID,
			trimmedClass,
		).Scan(&jadwalID)
		if err == nil {
			return jadwalID, nil
		}
	}

	// Fallback 3: match last scheduled lesson for this mentor
	var jadwalID int
	err = config.DB.QueryRow(
		context.Background(),
		`SELECT id
		 FROM jadwal
		 WHERE mentor_id = $1
		 ORDER BY id DESC
		 LIMIT 1`,
		mentorID,
	).Scan(&jadwalID)
	if err == nil {
		return jadwalID, nil
	}

	return 0, fmt.Errorf("jadwal mentor tidak ditemukan")
}

func StartAttendanceSessionHandler(c *gin.Context) {
	mentorIDAny, _ := c.Get("user_id")
	mentorID := mentorIDAny.(int)

	var input struct {
		ClassName string `json:"class_name"`
		Subject   string `json:"subject"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(400, gin.H{"error": "Payload tidak valid"})
		return
	}

	input.ClassName = strings.TrimSpace(input.ClassName)
	input.Subject = strings.TrimSpace(input.Subject)

	if input.ClassName == "" {
		input.ClassName = "Kelas Umum"
	}

	now := time.Now().UTC()
	hadirDeadline := now.Add(15 * time.Minute)
	terlambatDeadline := now.Add(15 * time.Minute)

	// Pastikan hanya satu sesi aktif per mentor.
	_, _ = config.DB.Exec(
		context.Background(),
		`UPDATE attendance_sessions
		 SET status = 'selesai'
		 WHERE mentor_id = $1 AND status = 'aktif'`,
		mentorID,
	)

	var sessionID int
	var token string

	for i := 0; i < 5; i++ {
		generated, err := generateAttendanceToken(6)
		if err != nil {
			c.JSON(500, gin.H{"error": "Gagal generate token absensi"})
			return
		}
		token = generated

		err = config.DB.QueryRow(
			context.Background(),
			`INSERT INTO attendance_sessions
			(mentor_id, class_name, subject, token, started_at, hadir_deadline, terlambat_deadline, status)
			VALUES ($1,$2,$3,$4,$5,$6,$7,'aktif')
			RETURNING id`,
			mentorID,
			input.ClassName,
			input.Subject,
			token,
			now,
			hadirDeadline,
			terlambatDeadline,
		).Scan(&sessionID)

		if err == nil {
			break
		}

		if !strings.Contains(strings.ToLower(err.Error()), "duplicate") {
			c.JSON(500, gin.H{"error": "Gagal membuat sesi absensi"})
			return
		}
	}

	if sessionID == 0 {
		c.JSON(500, gin.H{"error": "Gagal membuat token unik, coba lagi"})
		return
	}

	c.JSON(201, gin.H{
		"message":                 "Sesi absensi dimulai",
		"session_id":              sessionID,
		"token":                   token,
		"class_name":              input.ClassName,
		"subject":                 input.Subject,
		"started_at":              now,
		"started_at_unix":         now.Unix(),
		"hadir_deadline":          hadirDeadline,
		"hadir_deadline_unix":     hadirDeadline.Unix(),
		"terlambat_deadline":      terlambatDeadline,
		"terlambat_deadline_unix": terlambatDeadline.Unix(),
	})
}

func GetActiveAttendanceSessionHandler(c *gin.Context) {
	mentorIDAny, _ := c.Get("user_id")
	mentorID := mentorIDAny.(int)

	// Auto-close sesi kadaluarsa sebelum mengambil sesi aktif terbaru.
	_, _ = config.DB.Exec(
		context.Background(),
		`UPDATE attendance_sessions
		 SET status = 'selesai'
		 WHERE mentor_id = $1
		   AND status = 'aktif'
		   AND terlambat_deadline <= $2`,
		mentorID,
		time.Now().UTC(),
	)

	var session struct {
		ID               int
		ClassName        string
		Subject          string
		Token            string
		StartedAt        time.Time
		HadirDeadline    time.Time
		TerlambatDeadine time.Time
		Status           string
	}

	err := config.DB.QueryRow(
		context.Background(),
		`SELECT id, class_name, COALESCE(subject,''), token, started_at, hadir_deadline, terlambat_deadline, status
		 FROM attendance_sessions
		 WHERE mentor_id = $1
		   AND status = 'aktif'
		   AND terlambat_deadline > $2
		 ORDER BY started_at DESC
		 LIMIT 1`,
		mentorID,
		time.Now().UTC(),
	).Scan(
		&session.ID,
		&session.ClassName,
		&session.Subject,
		&session.Token,
		&session.StartedAt,
		&session.HadirDeadline,
		&session.TerlambatDeadine,
		&session.Status,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(200, gin.H{"session": nil})
			return
		}
		c.JSON(500, gin.H{"error": "Gagal mengambil sesi absensi"})
		return
	}

	c.JSON(200, gin.H{
		"session": gin.H{
			"id":                      session.ID,
			"class_name":              session.ClassName,
			"subject":                 session.Subject,
			"token":                   session.Token,
			"started_at":              session.StartedAt,
			"started_at_unix":         session.StartedAt.Unix(),
			"hadir_deadline":          session.HadirDeadline,
			"hadir_deadline_unix":     session.HadirDeadline.Unix(),
			"terlambat_deadline":      session.TerlambatDeadine,
			"terlambat_deadline_unix": session.TerlambatDeadine.Unix(),
			"status":                  session.Status,
		},
		"server_time_unix": time.Now().UTC().Unix(),
	})
}

func GetAttendanceSessionSummaryHandler(c *gin.Context) {
	mentorIDAny, _ := c.Get("user_id")
	mentorID := mentorIDAny.(int)
	sessionID := strings.TrimSpace(c.Param("sessionId"))

	if sessionID == "" {
		c.JSON(400, gin.H{"error": "sessionId wajib diisi"})
		return
	}

	var session struct {
		ID               int
		ClassName        string
		Subject          string
		Token            string
		StartedAt        time.Time
		HadirDeadline    time.Time
		TerlambatDeadine time.Time
		Status           string
	}

	err := config.DB.QueryRow(
		context.Background(),
		`SELECT id, class_name, COALESCE(subject,''), token, started_at, hadir_deadline, terlambat_deadline, status
		 FROM attendance_sessions
		 WHERE id = $1 AND mentor_id = $2`,
		sessionID,
		mentorID,
	).Scan(
		&session.ID,
		&session.ClassName,
		&session.Subject,
		&session.Token,
		&session.StartedAt,
		&session.HadirDeadline,
		&session.TerlambatDeadine,
		&session.Status,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(404, gin.H{"error": "Sesi absensi tidak ditemukan"})
			return
		}
		c.JSON(500, gin.H{"error": "Gagal membaca sesi absensi"})
		return
	}

	// Get all students in the class
	var classStudents []struct {
		SiswaID int // s.id
		UserID  int // s.user_id
		Nama    string
		Email   string
	}
	sRows, err := config.DB.Query(
		context.Background(),
		`SELECT s.id, s.user_id, 
		        COALESCE(NULLIF(u.nama,''), COALESCE(NULLIF(u.email,''), u.username), 'Siswa') AS nama,
		        COALESCE(NULLIF(u.email,''), u.username) AS email
		 FROM siswa s
		 JOIN users u ON s.user_id = u.id
		 WHERE LOWER(TRIM(s.kelas)) = LOWER(TRIM($1))
		 ORDER BY u.nama ASC`,
		session.ClassName,
	)
	if err == nil {
		for sRows.Next() {
			var cs struct {
				SiswaID int
				UserID  int
				Nama    string
				Email   string
			}
			if err := sRows.Scan(&cs.SiswaID, &cs.UserID, &cs.Nama, &cs.Email); err == nil {
				classStudents = append(classStudents, cs)
			}
		}
		sRows.Close()
	}

	// Get checked-in records
	type CheckInInfo struct {
		Status      string
		SubmittedAt time.Time
	}
	checkIns := make(map[int]CheckInInfo)
	arRows, err := config.DB.Query(
		context.Background(),
		`SELECT ar.siswa_id, ar.status, ar.submitted_at
		 FROM attendance_records ar
		 WHERE ar.session_id = $1`,
		session.ID,
	)
	if err == nil {
		defer arRows.Close()
		for arRows.Next() {
			var sID int
			var stat string
			var subAt time.Time
			if err := arRows.Scan(&sID, &stat, &subAt); err == nil {
				checkIns[sID] = CheckInInfo{Status: stat, SubmittedAt: subAt}
			}
		}
	}

	items := make([]gin.H, 0)
	hadirCount := 0
	tidakHadirCount := 0

	if len(classStudents) > 0 {
		for _, cs := range classStudents {
			info, ok := checkIns[cs.UserID] // Keyed by user_id
			status := "tidak_hadir"
			var submittedAt time.Time
			if ok {
				if info.Status == "tidak hadir" {
					status = "tidak_hadir"
				} else {
					status = info.Status
				}
				submittedAt = info.SubmittedAt
			}

			if status == "tidak_hadir" {
				tidakHadirCount++
			} else {
				hadirCount++
			}

			items = append(items, gin.H{
				"siswa_id":     cs.SiswaID, // s.id
				"nama":         cs.Nama,
				"email":        cs.Email,
				"status":       status,
				"submitted_at": submittedAt,
			})
		}
	} else {
		// Fallback to checked-in students if class is empty or has no students
		for sID, info := range checkIns { // sID is user_id
			var sDbID int // siswa.id
			var nama, email string
			err := config.DB.QueryRow(
				context.Background(),
				`SELECT s.id,
				        COALESCE(NULLIF(u.nama,''), COALESCE(NULLIF(u.email,''), u.username), 'Siswa'),
				        COALESCE(NULLIF(u.email,''), u.username)
				 FROM siswa s
				 JOIN users u ON s.user_id = u.id
				 WHERE u.id = $1`,
				sID,
			).Scan(&sDbID, &nama, &email)
			if err != nil {
				// Fallback if not found in siswa table
				sDbID = sID
				_ = config.DB.QueryRow(
					context.Background(),
					`SELECT COALESCE(NULLIF(nama,''), COALESCE(NULLIF(email,''), username), 'Siswa'),
					        COALESCE(NULLIF(email,''), username)
					 FROM users WHERE id = $1`,
					sID,
				).Scan(&nama, &email)
			}

			status := info.Status
			if status == "tidak hadir" {
				status = "tidak_hadir"
			}

			if status == "tidak_hadir" {
				tidakHadirCount++
			} else {
				hadirCount++
			}

			items = append(items, gin.H{
				"siswa_id":     sDbID, // Return sDbID (siswa.id)
				"nama":         nama,
				"email":        email,
				"status":       status,
				"submitted_at": info.SubmittedAt,
			})
		}
	}

	c.JSON(200, gin.H{
		"session": gin.H{
			"id":                      session.ID,
			"class_name":              session.ClassName,
			"subject":                 session.Subject,
			"token":                   session.Token,
			"started_at":              session.StartedAt,
			"started_at_unix":         session.StartedAt.Unix(),
			"hadir_deadline":          session.HadirDeadline,
			"hadir_deadline_unix":     session.HadirDeadline.Unix(),
			"terlambat_deadline":      session.TerlambatDeadine,
			"terlambat_deadline_unix": session.TerlambatDeadine.Unix(),
			"status":                  session.Status,
		},
		"summary": gin.H{
			"hadir":       hadirCount,
			"tidak_hadir": tidakHadirCount,
			"total_masuk": hadirCount + tidakHadirCount,
		},
		"records": items,
	})
}

func SubmitAttendanceTokenHandler(c *gin.Context) {
	siswaIDAny, _ := c.Get("user_id")
	siswaID := siswaIDAny.(int)

	var input struct {
		Token string `json:"token"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(400, gin.H{"error": "Payload tidak valid"})
		return
	}

	input.Token = strings.ToUpper(strings.TrimSpace(input.Token))
	if input.Token == "" {
		c.JSON(400, gin.H{"error": "Token wajib diisi"})
		return
	}

	var session struct {
		ID               int
		MentorID         int
		ClassName        string
		Subject          string
		Token            string
		StartedAt        time.Time
		HadirDeadline    time.Time
		TerlambatDeadine time.Time
		Status           string
	}

	err := config.DB.QueryRow(
		context.Background(),
		`SELECT id, mentor_id, class_name, COALESCE(subject,''), token, started_at, hadir_deadline, terlambat_deadline, status
		 FROM attendance_sessions
		 WHERE token = $1
		 ORDER BY started_at DESC
		 LIMIT 1`,
		input.Token,
	).Scan(
		&session.ID,
		&session.MentorID,
		&session.ClassName,
		&session.Subject,
		&session.Token,
		&session.StartedAt,
		&session.HadirDeadline,
		&session.TerlambatDeadine,
		&session.Status,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(404, gin.H{"error": "Token tidak ditemukan"})
			return
		}
		c.JSON(500, gin.H{"error": "Gagal membaca token absensi"})
		return
	}

	siswaDBID, err := resolveSiswaDatabaseID(siswaID)
	if err != nil {
		c.JSON(404, gin.H{"error": err.Error()})
		return
	}

	jadwalID, err := resolveJadwalIDForAttendance(session.MentorID, session.Subject, session.ClassName)
	if err != nil {
		c.JSON(404, gin.H{"error": err.Error()})
		return
	}

	var existingStatus string
	var existingSubmittedAt time.Time
	existingErr := config.DB.QueryRow(
		context.Background(),
		`SELECT status, submitted_at FROM attendance_records WHERE session_id = $1 AND siswa_id = $2`,
		session.ID,
		siswaID,
	).Scan(&existingStatus, &existingSubmittedAt)

	if existingErr == nil {
		c.JSON(200, gin.H{
			"message": "Kamu sudah melakukan absensi sebelumnya",
			"attendance": gin.H{
				"session_id":         session.ID,
				"class_name":         session.ClassName,
				"subject":            session.Subject,
				"status":             existingStatus,
				"submitted_at":       existingSubmittedAt,
				"hadir_deadline":     session.HadirDeadline,
				"terlambat_deadline": session.TerlambatDeadine,
			},
		})
		return
	}

	if !errors.Is(existingErr, pgx.ErrNoRows) {
		c.JSON(500, gin.H{"error": "Gagal memeriksa data absensi"})
		return
	}

	now := time.Now().UTC()
	if now.After(session.HadirDeadline) {
		_, _ = config.DB.Exec(
			context.Background(),
			`UPDATE attendance_sessions SET status = 'selesai' WHERE id = $1`,
			session.ID,
		)
		c.JSON(400, gin.H{"error": "Waktu absensi telah habis (maksimal 15 menit)"})
		return
	}
	attendanceStatus := "hadir"

	_, err = config.DB.Exec(
		context.Background(),
		`INSERT INTO absensi (siswa_id, jadwal_id, status, tanggal)
		 VALUES ($1,$2,$3,$4)`,
		siswaDBID,
		jadwalID,
		attendanceStatus,
		now,
	)
	if err != nil {
		c.JSON(500, gin.H{"error": "Gagal menyimpan absensi ke tabel absensi"})
		return
	}

	_, err = config.DB.Exec(
		context.Background(),
		`INSERT INTO attendance_records (session_id, siswa_id, status, submitted_at)
		 VALUES ($1,$2,$3,$4)`,
		session.ID,
		siswaID,
		attendanceStatus,
		now,
	)
	if err != nil {
		c.JSON(500, gin.H{"error": "Gagal menyimpan absensi"})
		return
	}

	message := "Absensi berhasil, status kamu hadir"

	c.JSON(200, gin.H{
		"message": message,
		"attendance": gin.H{
			"session_id":              session.ID,
			"class_name":              session.ClassName,
			"subject":                 session.Subject,
			"status":                  attendanceStatus,
			"submitted_at":            now,
			"submitted_at_unix":       now.Unix(),
			"hadir_deadline":          session.HadirDeadline,
			"hadir_deadline_unix":     session.HadirDeadline.Unix(),
			"terlambat_deadline":      session.TerlambatDeadine,
			"terlambat_deadline_unix": session.TerlambatDeadine.Unix(),
		},
	})
}

func GetStudentAttendanceHistoryHandler(c *gin.Context) {
	siswaIDAny, _ := c.Get("user_id")
	siswaID := siswaIDAny.(int)

	classNameFilter := strings.TrimSpace(c.Query("class_name"))
	statusFilter := strings.TrimSpace(c.Query("status"))
	dateFilter := strings.TrimSpace(c.Query("date"))

	whereClauses := []string{"ar.siswa_id = $1"}
	args := []any{siswaID}
	argPos := 2

	if classNameFilter != "" {
		whereClauses = append(whereClauses, fmt.Sprintf("LOWER(s.class_name) = LOWER($%d)", argPos))
		args = append(args, classNameFilter)
		argPos++
	}

	if statusFilter != "" {
		whereClauses = append(whereClauses, fmt.Sprintf("ar.status = $%d", argPos))
		args = append(args, statusFilter)
		argPos++
	}

	if dateFilter != "" {
		selectedDate, err := time.Parse("2006-01-02", dateFilter)
		if err != nil {
			c.JSON(400, gin.H{"error": "Format date wajib YYYY-MM-DD"})
			return
		}

		startAt := time.Date(selectedDate.Year(), selectedDate.Month(), selectedDate.Day(), 0, 0, 0, 0, time.Local)
		endAt := startAt.Add(24 * time.Hour)

		whereClauses = append(whereClauses, fmt.Sprintf("ar.submitted_at >= $%d", argPos))
		args = append(args, startAt)
		argPos++

		whereClauses = append(whereClauses, fmt.Sprintf("ar.submitted_at < $%d", argPos))
		args = append(args, endAt)
		argPos++
	}

	query := fmt.Sprintf(`SELECT ar.id,
	        ar.status,
	        ar.submitted_at,
	        s.class_name,
	        COALESCE(s.subject,''),
	        s.started_at
	 FROM attendance_records ar
	 JOIN attendance_sessions s ON s.id = ar.session_id
	 WHERE %s
	 ORDER BY ar.submitted_at DESC
	 LIMIT 50`, strings.Join(whereClauses, " AND "))

	rows, err := config.DB.Query(
		context.Background(),
		query,
		args...,
	)
	if err != nil {
		c.JSON(500, gin.H{"error": "Gagal mengambil riwayat absensi"})
		return
	}
	defer rows.Close()

	history := make([]gin.H, 0)
	for rows.Next() {
		var id int
		var status, className, subject string
		var submittedAt, startedAt time.Time

		if err := rows.Scan(&id, &status, &submittedAt, &className, &subject, &startedAt); err != nil {
			c.JSON(500, gin.H{"error": "Gagal memproses riwayat absensi"})
			return
		}

		history = append(history, gin.H{
			"id":           id,
			"status":       status,
			"submitted_at": submittedAt,
			"class_name":   className,
			"subject":      subject,
			"started_at":   startedAt,
		})
	}

	c.JSON(200, gin.H{
		"data": history,
		"filters": gin.H{
			"class_name": classNameFilter,
			"status":     statusFilter,
			"date":       dateFilter,
		},
	})
}

func DebugAttendanceExplainHandler(c *gin.Context) {
	now := time.Now()
	c.JSON(200, gin.H{
		"message": "Rule absensi aktif",
		"rule": []string{
			"0-15 menit sejak token dibuat: hadir",
			"lebih dari 15 sampai 30 menit: terlambat",
			"lebih dari 30 menit: tidak_hadir",
		},
		"server_time": fmt.Sprintf("%s", now.Format(time.RFC3339)),
	})
}

func GetActiveAttendanceSessionForSiswaHandler(c *gin.Context) {
	// Auto-close expired sessions before checking
	_, _ = config.DB.Exec(
		context.Background(),
		`UPDATE attendance_sessions
		 SET status = 'selesai'
		 WHERE status = 'aktif'
		   AND hadir_deadline <= $1`,
		time.Now().UTC(),
	)

	var session struct {
		ID            int
		ClassName     string
		Subject       string
		StartedAt     time.Time
		HadirDeadline time.Time
		Status        string
	}

	err := config.DB.QueryRow(
		context.Background(),
		`SELECT id, class_name, COALESCE(subject,''), started_at, hadir_deadline, status
		 FROM attendance_sessions
		 WHERE status = 'aktif'
		   AND hadir_deadline > $1
		 ORDER BY started_at DESC
		 LIMIT 1`,
		time.Now().UTC(),
	).Scan(
		&session.ID,
		&session.ClassName,
		&session.Subject,
		&session.StartedAt,
		&session.HadirDeadline,
		&session.Status,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(200, gin.H{"session": nil})
			return
		}
		c.JSON(500, gin.H{"error": "Gagal mengambil sesi absensi aktif"})
		return
	}

	c.JSON(200, gin.H{
		"session": gin.H{
			"id":                  session.ID,
			"class_name":          session.ClassName,
			"subject":             session.Subject,
			"started_at_unix":     session.StartedAt.Unix(),
			"hadir_deadline_unix": session.HadirDeadline.Unix(),
			"status":              session.Status,
		},
		"server_time_unix": time.Now().UTC().Unix(),
	})
}

func GetAdminAttendanceSessionsHandler(c *gin.Context) {
	// Count total absensi records
	var totalAbsensi int
	_ = config.DB.QueryRow(context.Background(), `SELECT COUNT(*) FROM absensi`).Scan(&totalAbsensi)

	// Count total hadir
	var totalHadir int
	_ = config.DB.QueryRow(context.Background(), `SELECT COUNT(*) FROM absensi WHERE status = 'hadir'`).Scan(&totalHadir)

	// Count total tidak hadir
	var totalTidakHadir int
	_ = config.DB.QueryRow(context.Background(), `SELECT COUNT(*) FROM absensi WHERE status = 'tidak hadir'`).Scan(&totalTidakHadir)

	// Set custom HTTP response headers
	c.Writer.Header().Set("x-total-sesi", fmt.Sprintf("%d", totalAbsensi))
	c.Writer.Header().Set("x-total-hadir", fmt.Sprintf("%d", totalHadir))
	c.Writer.Header().Set("x-total-tidak-hadir", fmt.Sprintf("%d", totalTidakHadir))

	rows, err := config.DB.Query(
		context.Background(),
		`SELECT 
			a.id, 
			a.tanggal, 
			u_siswa.nama AS nama_siswa, 
			s.kelas AS kelas_siswa, 
			j.mata_pelajaran, 
			u_mentor.nama AS nama_mentor, 
			a.status, 
			s.id AS siswa_id
		 FROM absensi a
		 JOIN siswa s ON a.siswa_id = s.id
		 JOIN users u_siswa ON s.user_id = u_siswa.id
		 JOIN jadwal j ON a.jadwal_id = j.id
		 JOIN mentor m ON j.mentor_id = m.id
		 JOIN users u_mentor ON m.user_id = u_mentor.id
		 ORDER BY a.tanggal DESC`,
	)
	if err != nil {
		c.JSON(500, gin.H{"error": "Gagal mengambil data absensi admin: " + err.Error()})
		return
	}
	defer rows.Close()

	list := make([]gin.H, 0)
	for rows.Next() {
		var absensiID, siswaID int
		var tanggal time.Time
		var siswaName, kelasSiswa, subject, mentorName, statusStr string
		if err := rows.Scan(&absensiID, &tanggal, &siswaName, &kelasSiswa, &subject, &mentorName, &statusStr, &siswaID); err != nil {
			c.JSON(500, gin.H{"error": "Gagal membaca baris absensi: " + err.Error()})
			return
		}

		displayStatus := "Hadir"
		if statusStr == "tidak hadir" {
			displayStatus = "Tidak Hadir"
		}

		// Format tanggal and jam
		localTime := tanggal.Local()
		tanggalStr := localTime.Format("02/01/2006")
		jamStr := localTime.Format("15:04")

		list = append(list, gin.H{
			"id":       absensiID,
			"tanggal":  tanggalStr,
			"jam":      jamStr,
			"siswa":    siswaName,
			"kelas":    kelasSiswa,
			"mapel":    subject,
			"mentor":   mentorName,
			"status":   displayStatus,
			"siswa_id": siswaID,
		})
	}

	c.JSON(200, list)
}

func DownloadStudentAttendancePDFHandler(c *gin.Context) {
	siswaIDStr := c.Param("siswaId")
	if siswaIDStr == "" {
		siswaIDStr = c.Query("siswa_id")
	}
	siswaID, err := strconv.Atoi(siswaIDStr)
	if err != nil || siswaID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID siswa tidak valid"})
		return
	}

	// 1. Fetch Student Details
	var studentName, studentClass, studentSchool string
	err = config.DB.QueryRow(context.Background(), `
		SELECT u.nama, s.kelas, s.asal_sekolah
		FROM siswa s
		JOIN users u ON s.user_id = u.id
		WHERE s.id = $1
	`, siswaID).Scan(&studentName, &studentClass, &studentSchool)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Siswa tidak ditemukan"})
		return
	}

	// 2. Fetch Attendance Records for this Student
	rows, err := config.DB.Query(context.Background(), `
		SELECT a.tanggal, j.mata_pelajaran, u_mentor.nama AS nama_mentor, a.status
		FROM absensi a
		JOIN jadwal j ON a.jadwal_id = j.id
		JOIN mentor m ON j.mentor_id = m.id
		JOIN users u_mentor ON m.user_id = u_mentor.id
		WHERE a.siswa_id = $1
		ORDER BY a.tanggal DESC
	`, siswaID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil riwayat absensi: " + err.Error()})
		return
	}
	defer rows.Close()

	type AttendanceRow struct {
		Tanggal string
		Mapel   string
		Mentor  string
		Status  string
	}

	var records []AttendanceRow
	hadirCount := 0
	tidakHadirCount := 0

	for rows.Next() {
		var t time.Time
		var mapel, mentor, status string
		if err := rows.Scan(&t, &mapel, &mentor, &status); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membaca baris absensi"})
			return
		}

		displayStatus := "HADIR"
		if status == "tidak hadir" {
			displayStatus = "TIDAK HADIR"
			tidakHadirCount++
		} else {
			hadirCount++
		}

		records = append(records, AttendanceRow{
			Tanggal: t.Local().Format("02/01/2006 15:04"),
			Mapel:   mapel,
			Mentor:  mentor,
			Status:  displayStatus,
		})
	}

	totalMeetings := len(records)
	attendancePercentage := 0.0
	if totalMeetings > 0 {
		attendancePercentage = float64(hadirCount) / float64(totalMeetings) * 100.0
	}

	// 3. Generate PDF using gofpdf
	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.AddPage()
	pdf.SetMargins(15, 15, 15)

	// -- Header / Kop Surat --
	pdf.SetFillColor(240, 244, 255)
	pdf.Rect(15, 15, 180, 28, "F")
	
	pdf.SetFont("Arial", "B", 16)
	pdf.SetTextColor(30, 64, 175) // Deep Blue
	pdf.CellFormat(180, 10, "BINTANG MUDA CENTER (BMC GROWUP)", "", 1, "C", false, 0, "")
	
	pdf.SetFont("Arial", "I", 10)
	pdf.SetTextColor(75, 85, 99) // Gray
	pdf.CellFormat(180, 6, "Laporan Rekapitulasi Absensi Siswa Resmi", "", 1, "C", false, 0, "")
	pdf.Ln(8)

	// -- Student Details Box --
	pdf.SetDrawColor(229, 231, 235)
	pdf.SetLineWidth(0.3)
	pdf.SetFillColor(255, 255, 255)
	pdf.Rect(15, 52, 180, 25, "DF")

	pdf.SetFont("Arial", "B", 10)
	pdf.SetTextColor(31, 41, 55)
	pdf.Text(18, 58, "Informasi Siswa:")

	pdf.SetFont("Arial", "", 10)
	pdf.Text(18, 64, fmt.Sprintf("Nama Lengkap : %s", studentName))
	pdf.Text(18, 70, fmt.Sprintf("Kelas                 : %s", studentClass))
	pdf.Text(110, 64, fmt.Sprintf("Asal Sekolah : %s", studentSchool))
	pdf.Text(110, 70, fmt.Sprintf("Tanggal Cetak: %s", time.Now().Local().Format("02/01/2006")))

	// Crucial: Set Y position to Y=82 to cleanly position the statistics box
	pdf.SetY(82)

	// -- Statistics Row (using clean grid format) --
	colStatWidth := 180.0 / 4.0 // 45.0 mm each
	
	// Headers for Stats
	pdf.SetFont("Arial", "B", 9)
	pdf.SetTextColor(75, 85, 99)
	pdf.SetFillColor(243, 244, 246)
	pdf.CellFormat(colStatWidth, 6, "TOTAL PERTEMUAN", "1", 0, "C", true, 0, "")
	pdf.CellFormat(colStatWidth, 6, "HADIR", "1", 0, "C", true, 0, "")
	pdf.CellFormat(colStatWidth, 6, "TIDAK HADIR", "1", 0, "C", true, 0, "")
	pdf.CellFormat(colStatWidth, 6, "PERSENTASE", "1", 1, "C", true, 0, "") // 1 means next line
	
	// Values for Stats
	pdf.SetFont("Arial", "B", 12)
	pdf.SetFillColor(255, 255, 255)
	
	// Total
	pdf.SetTextColor(17, 24, 39)
	pdf.CellFormat(colStatWidth, 10, fmt.Sprintf("%d", totalMeetings), "1", 0, "C", false, 0, "")
	
	// Hadir
	pdf.SetTextColor(16, 124, 65)
	pdf.CellFormat(colStatWidth, 10, fmt.Sprintf("%d", hadirCount), "1", 0, "C", false, 0, "")
	
	// Tidak Hadir
	pdf.SetTextColor(220, 38, 38)
	pdf.CellFormat(colStatWidth, 10, fmt.Sprintf("%d", tidakHadirCount), "1", 0, "C", false, 0, "")
	
	// Persentase
	pdf.SetTextColor(30, 64, 175)
	pdf.CellFormat(colStatWidth, 10, fmt.Sprintf("%.1f%%", attendancePercentage), "1", 1, "C", false, 0, "")
	
	pdf.Ln(6)

	// -- History Table Header --
	pdf.SetFont("Arial", "B", 10)
	pdf.SetTextColor(31, 41, 55)
	pdf.CellFormat(180, 8, "Detail Riwayat Kehadiran Sesi", "", 1, "L", false, 0, "")
	pdf.Ln(2)

	// Table column widths
	colWidths := []float64{12, 45, 63, 40, 20} // Total = 180
	headers := []string{"No", "Tanggal & Jam", "Mata Pelajaran", "Mentor", "Status"}

	pdf.SetFillColor(37, 99, 235) // Primary Blue
	pdf.SetTextColor(255, 255, 255)
	pdf.SetFont("Arial", "B", 9)
	
	for i, h := range headers {
		align := "L"
		if i == 0 || i == 4 {
			align = "C"
		}
		pdf.CellFormat(colWidths[i], 8, h, "1", 0, align, true, 0, "")
	}
	pdf.Ln(8)

	// Table Rows
	pdf.SetTextColor(55, 65, 81)
	pdf.SetFont("Arial", "", 8.5)
	
	for idx, rec := range records {
		bg := false
		if idx%2 == 1 {
			bg = true
			pdf.SetFillColor(249, 250, 251)
		}
		
		statusColor := func() {
			if rec.Status == "HADIR" {
				pdf.SetTextColor(16, 124, 65) // Green
			} else {
				pdf.SetTextColor(220, 38, 38) // Red
			}
		}

		pdf.CellFormat(colWidths[0], 7, fmt.Sprintf("%d", idx+1), "1", 0, "C", bg, 0, "")
		pdf.CellFormat(colWidths[1], 7, rec.Tanggal, "1", 0, "L", bg, 0, "")
		pdf.CellFormat(colWidths[2], 7, rec.Mapel, "1", 0, "L", bg, 0, "")
		pdf.CellFormat(colWidths[3], 7, rec.Mentor, "1", 0, "L", bg, 0, "")
		
		statusColor()
		pdf.SetFont("Arial", "B", 8.5)
		pdf.CellFormat(colWidths[4], 7, rec.Status, "1", 1, "C", bg, 0, "")
		
		pdf.SetTextColor(55, 65, 81)
		pdf.SetFont("Arial", "", 8.5)
	}

	// Signatures / Footer
	pdf.Ln(10)
	pdf.SetFont("Arial", "", 9)
	pdf.SetTextColor(107, 114, 128)
	pdf.CellFormat(180, 5, "* Laporan ini sah dicetak oleh sistem administrasi BMC GROWUP.", "", 1, "C", false, 0, "")

	// Set content-type and headers for download
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=Laporan_Absensi_%s.pdf", strings.ReplaceAll(studentName, " ", "_")))
	c.Header("Content-Type", "application/pdf")
	
	err = pdf.Output(c.Writer)
	if err != nil {
		log.Println("Error generating PDF output:", err)
	}
}

// ResetAllAttendanceHandler resets all attendance sessions, records, and legacy absensi data
func ResetAllAttendanceHandler(c *gin.Context) {
	tx, err := config.DB.Begin(context.Background())
	if err != nil {
		c.JSON(500, gin.H{"error": "Gagal memulai transaksi: " + err.Error()})
		return
	}
	defer tx.Rollback(context.Background())

	// 1. Delete all records from legacy table
	_, err = tx.Exec(context.Background(), `DELETE FROM absensi`)
	if err != nil {
		c.JSON(500, gin.H{"error": "Gagal menghapus data legacy absensi: " + err.Error()})
		return
	}

	// 2. Delete all records from attendance_records
	_, err = tx.Exec(context.Background(), `DELETE FROM attendance_records`)
	if err != nil {
		c.JSON(500, gin.H{"error": "Gagal menghapus catatan kehadiran siswa: " + err.Error()})
		return
	}

	// 3. Delete all records from attendance_sessions
	_, err = tx.Exec(context.Background(), `DELETE FROM attendance_sessions`)
	if err != nil {
		c.JSON(500, gin.H{"error": "Gagal menghapus sesi absensi: " + err.Error()})
		return
	}

	err = tx.Commit(context.Background())
	if err != nil {
		c.JSON(500, gin.H{"error": "Gagal menyelesaikan transaksi: " + err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Semua data absensi berhasil diriset"})
}

