package handlers

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"strings"
	"time"

	"bmcgoapp-backend/config"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
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

func resolveJadwalIDForAttendance(mentorUserID int, subject string) (int, error) {
	mentorID, err := resolveMentorDatabaseID(mentorUserID)
	if err != nil {
		return 0, err
	}

	trimmedSubject := strings.TrimSpace(subject)
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

	rows, err := config.DB.Query(
		context.Background(),
		`SELECT ar.siswa_id,
		        COALESCE(NULLIF(u.nama,''), COALESCE(NULLIF(u.email,''), u.username), 'Siswa') AS nama,
		        COALESCE(NULLIF(u.email,''), u.username) AS email,
		        ar.status,
		        ar.submitted_at
		 FROM attendance_records ar
		 LEFT JOIN users u ON u.id = ar.siswa_id
		 WHERE ar.session_id = $1
		 ORDER BY ar.submitted_at ASC`,
		session.ID,
	)
	if err != nil {
		c.JSON(500, gin.H{"error": "Gagal membaca data absensi"})
		return
	}
	defer rows.Close()

	items := make([]gin.H, 0)
	hadirCount := 0
	terlambatCount := 0
	tidakHadirCount := 0

	for rows.Next() {
		var siswaID int
		var nama, email, status string
		var submittedAt time.Time

		if err := rows.Scan(&siswaID, &nama, &email, &status, &submittedAt); err != nil {
			c.JSON(500, gin.H{"error": "Gagal memproses data absensi"})
			return
		}

		switch status {
		case "hadir":
			hadirCount++
		case "terlambat":
			terlambatCount++
		case "tidak_hadir":
			tidakHadirCount++
		}

		items = append(items, gin.H{
			"siswa_id":     siswaID,
			"nama":         nama,
			"email":        email,
			"status":       status,
			"submitted_at": submittedAt,
		})
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
			"terlambat":   terlambatCount,
			"tidak_hadir": tidakHadirCount,
			"total_masuk": hadirCount + terlambatCount + tidakHadirCount,
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

	jadwalID, err := resolveJadwalIDForAttendance(session.MentorID, session.Subject)
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
	switch attendanceStatus {
	case "terlambat":
		message = "Absensi tercatat, status kamu terlambat"
	case "tidak_hadir":
		message = "Waktu absensi habis, status kamu tidak hadir"
	}

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
