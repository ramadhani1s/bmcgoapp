package handlers

import (
	"bmcgoapp-backend/config"
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

type adminDashboardStats struct {
	PendingVerifications int `json:"pending_verifications"`
	SchedulesToday       int `json:"schedules_today"`
	ActiveStudents       int `json:"active_students"`
}

type adminPendingVerificationRow struct {
	TransactionID string `json:"transaction_id"`
	Name          string `json:"name"`
	School        string `json:"school"`
	ClassName     string `json:"class_name"`
	Date          string `json:"date"`
	Status        string `json:"status"`
}

type adminScheduleRow struct {
	Time      string `json:"time"`
	ClassName string `json:"class_name"`
	Subject   string `json:"subject"`
	Mentor    string `json:"mentor"`
	Room      string `json:"room"`
	Status    string `json:"status"`
}

type adminDashboardData struct {
	Stats                adminDashboardStats           `json:"stats"`
	PendingVerifications []adminPendingVerificationRow `json:"pending_verifications"`
	TodaySchedules       []adminScheduleRow            `json:"today_schedules"`
	ScheduleDateLabel    string                        `json:"schedule_date_label"`
}

// GetAdminDashboard mengembalikan ringkasan dashboard admin yang siap dipakai frontend.
func GetAdminDashboard(c *gin.Context) {
	ctx := c.Request.Context()
	now := time.Now()

	pendingRows, err := loadPendingVerificationRows(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"message": "Failed to load dashboard data",
			"error":   err.Error(),
		})
		return
	}

	activeStudents, err := loadActiveStudentsCount(ctx)
	if err != nil {
		activeStudents = 0
	}

	schedules, err := loadTodaySchedules(ctx, now)
	if err != nil {
		schedules = []adminScheduleRow{}
	}

	data := adminDashboardData{
		Stats: adminDashboardStats{
			PendingVerifications: len(pendingRows),
			SchedulesToday:       len(schedules),
			ActiveStudents:       activeStudents,
		},
		PendingVerifications: pendingRows,
		TodaySchedules:       schedules,
		ScheduleDateLabel:    formatIndoDate(now),
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Admin dashboard data",
		"data":    data,
	})
}

func loadPendingVerificationRows(ctx context.Context) ([]adminPendingVerificationRow, error) {
	query := `
		SELECT pt.transaction_id,
		       COALESCE(NULLIF(TRIM(s.nama_siswa), ''), NULLIF(TRIM(u.nama), ''), NULLIF(TRIM(pt.customer_name), ''), '-') AS nama_siswa,
		       COALESCE(NULLIF(TRIM(s.asal_sekolah), ''), '-') AS asal_sekolah,
		       COALESCE(NULLIF(TRIM(s.kelas), ''), '-') AS kelas,
		       pt.created_at
		FROM payment_transactions pt
		LEFT JOIN users u ON u.id = pt.user_id
		LEFT JOIN siswa s ON s.user_id = pt.user_id
		WHERE pt.status = 'success' AND pt.is_verified = FALSE
		ORDER BY created_at DESC
		LIMIT 10`

	rows, err := config.DB.Query(ctx, query)
	if err != nil {
		if isUndefinedTableError(err) {
			return []adminPendingVerificationRow{}, nil
		}
		return nil, err
	}
	defer rows.Close()

	items := make([]adminPendingVerificationRow, 0)
	for rows.Next() {
		var transactionID string
		var studentName string
		var school string
		var className string
		var createdAt time.Time
		if err := rows.Scan(&transactionID, &studentName, &school, &className, &createdAt); err != nil {
			return nil, err
		}

		name := strings.TrimSpace(studentName)
		if name == "" {
			name = "-"
		}

		items = append(items, adminPendingVerificationRow{
			TransactionID: transactionID,
			Name:          name,
			School:        school,
			ClassName:     className,
			Date:          formatShortIndoDate(createdAt),
			Status:        "Menunggu",
		})
	}

	if rows.Err() != nil {
		return nil, rows.Err()
	}

	return items, nil
}

func loadActiveStudentsCount(ctx context.Context) (int, error) {
	var count int
	err := config.DB.QueryRow(
		ctx,
		`SELECT COUNT(DISTINCT user_id)
		 FROM payment_transactions
		 WHERE status = 'success' AND is_verified = TRUE`,
	).Scan(&count)
	if err != nil {
		if isUndefinedTableError(err) {
			return 0, nil
		}
		return 0, err
	}

	if count > 0 {
		return count, nil
	}

	// Fallback agar tetap ada angka walau belum ada data verifikasi pembayaran.
	err = config.DB.QueryRow(
		ctx,
		`SELECT COUNT(*) FROM users WHERE role_id = 3 AND status = 'aktif'`,
	).Scan(&count)
	if err != nil {
		if isUndefinedTableError(err) {
			return 0, nil
		}
		return 0, err
	}

	return count, nil
}

func loadTodaySchedules(ctx context.Context, now time.Time) ([]adminScheduleRow, error) {
	exists, err := tableExists(ctx, "jadwal")
	if err != nil {
		return nil, err
	}
	if !exists {
		return []adminScheduleRow{}, nil
	}

	query := `
		SELECT
			COALESCE(j.jam_mulai::text, '-') || ' - ' || COALESCE(j.jam_selesai::text, '-') AS waktu,
			COALESCE(j.kelas, '-') AS kelas,
			COALESCE(j.mata_pelajaran, '-') AS mata_pelajaran,
			COALESCE(j.mentor_nama, '-') AS mentor,
			COALESCE(j.ruang, '-') AS ruang,
			COALESCE(j.status, 'Akan Datang') AS status
		FROM jadwal j
		WHERE DATE(j.tanggal) = DATE($1)
		ORDER BY j.jam_mulai ASC
		LIMIT 20`

	rows, err := config.DB.Query(ctx, query, now)
	if err != nil {
		if isUndefinedColumnError(err) {
			return []adminScheduleRow{}, nil
		}
		return nil, err
	}
	defer rows.Close()

	schedules := make([]adminScheduleRow, 0)
	for rows.Next() {
		row := adminScheduleRow{}
		if err := rows.Scan(
			&row.Time,
			&row.ClassName,
			&row.Subject,
			&row.Mentor,
			&row.Room,
			&row.Status,
		); err != nil {
			return nil, err
		}
		schedules = append(schedules, row)
	}

	if rows.Err() != nil {
		return nil, rows.Err()
	}

	return schedules, nil
}

func tableExists(ctx context.Context, tableName string) (bool, error) {
	var exists bool
	err := config.DB.QueryRow(
		ctx,
		`SELECT EXISTS (
			SELECT 1
			FROM information_schema.tables
			WHERE table_schema = 'public' AND table_name = $1
		)`,
		tableName,
	).Scan(&exists)
	if err != nil {
		return false, err
	}
	return exists, nil
}

func isUndefinedTableError(err error) bool {
	return strings.Contains(strings.ToLower(err.Error()), "relation") && strings.Contains(strings.ToLower(err.Error()), "does not exist")
}

func isUndefinedColumnError(err error) bool {
	lower := strings.ToLower(err.Error())
	return strings.Contains(lower, "column") && strings.Contains(lower, "does not exist")
}

func formatShortIndoDate(date time.Time) string {
	months := []string{
		"Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
	}
	month := "-"
	if int(date.Month()) >= 1 && int(date.Month()) <= len(months) {
		month = months[int(date.Month())-1]
	}
	return fmt.Sprintf("%d %s %d", date.Day(), month, date.Year())
}

func formatIndoDate(date time.Time) string {
	days := []string{"Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"}
	months := []string{
		"Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember",
	}
	day := days[int(date.Weekday())]
	month := months[int(date.Month())-1]
	return fmt.Sprintf("%s, %d %s %d", day, date.Day(), month, date.Year())
}
