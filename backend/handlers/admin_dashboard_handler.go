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

type DashboardPendingItem struct {
	StudentName string    `json:"student_name"`
	SchoolName  string    `json:"school_name"`
	ClassName   string    `json:"class_name"`
	Date        time.Time `json:"date"`
	Status      string    `json:"status"`
}

type DashboardSummary struct {
	WaitingVerifications int                    `json:"waiting_verifications"`
	TodaySchedules       int                    `json:"today_schedules"`
	ActiveStudents       int                    `json:"active_students"`
	PendingItems         []DashboardPendingItem `json:"pending_items"`
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

func findScheduleTable(ctx context.Context) (string, error) {
	candidates := []string{"jadwal", "jadwal_belajar", "schedules", "schedule"}
	for _, candidate := range candidates {
		exists, err := tableExists(ctx, candidate)
		if err != nil {
			return "", err
		}
		if exists {
			return candidate, nil
		}
	}
	return "", nil
}

func findDateColumn(ctx context.Context, tableName string) (string, error) {
	rows, err := config.DB.Query(
		ctx,
		`SELECT column_name
		 FROM information_schema.columns
		 WHERE table_schema = 'public' AND table_name = $1`,
		tableName,
	)
	if err != nil {
		return "", err
	}
	defer rows.Close()

	columns := make(map[string]bool)
	for rows.Next() {
		var name string
		if scanErr := rows.Scan(&name); scanErr != nil {
			return "", scanErr
		}
		columns[strings.ToLower(name)] = true
	}

	for _, candidate := range []string{"tanggal", "jadwal_date", "schedule_date", "date", "created_at"} {
		if columns[candidate] {
			return candidate, nil
		}
	}

	return "", nil
}

func countTodaySchedules(ctx context.Context) (int, error) {
	tableName, err := findScheduleTable(ctx)
	if err != nil {
		return 0, err
	}
	if tableName == "" {
		return 0, nil
	}

	dateColumn, err := findDateColumn(ctx, tableName)
	if err != nil {
		return 0, err
	}
	if dateColumn == "" {
		return 0, nil
	}

	query := fmt.Sprintf("SELECT COUNT(*) FROM %s WHERE DATE(%s) = CURRENT_DATE", tableName, dateColumn)
	var count int
	if err := config.DB.QueryRow(ctx, query).Scan(&count); err != nil {
		return 0, nil
	}

	return count, nil
}

func mapVerificationStatus(rawStatus string, isVerified bool) string {
	status := strings.ToLower(strings.TrimSpace(rawStatus))
	if isVerified {
		return "Disetujui"
	}

	if status == "failed" || status == "deny" || status == "cancel" || status == "expire" {
		return "Ditolak"
	}

	return "Menunggu"
}

// GetAdminDashboard tetap disediakan untuk kompatibilitas endpoint lama.
func GetAdminDashboard(c *gin.Context) {
	GetAdminDashboardSummary(c)
}

// GetAdminDashboardSummary menyediakan ringkasan dashboard admin yang dinamis.
func GetAdminDashboardSummary(c *gin.Context) {
	ctx := c.Request.Context()
	summary := DashboardSummary{}

	if err := config.DB.QueryRow(
		ctx,
		`SELECT COUNT(*)
		 FROM (
			SELECT DISTINCT ON (pt.user_id)
				pt.user_id,
				pt.status,
				COALESCE(pt.is_verified, FALSE) AS is_verified
			FROM payment_transactions pt
			ORDER BY pt.user_id, pt.created_at DESC
		) latest
		WHERE latest.status IN ('success', 'pending') AND latest.is_verified = FALSE`,
	).Scan(&summary.WaitingVerifications); err != nil {
		summary.WaitingVerifications = 0
	}

	if err := config.DB.QueryRow(
		ctx,
		`SELECT COUNT(*)
		 FROM users
		 WHERE role_id = 3 AND LOWER(COALESCE(status, '')) = 'aktif'`,
	).Scan(&summary.ActiveStudents); err != nil {
		summary.ActiveStudents = 0
	}

	scheduleCount, err := countTodaySchedules(ctx)
	if err != nil {
		scheduleCount = 0
	}
	summary.TodaySchedules = scheduleCount

	rows, err := config.DB.Query(
		ctx,
		`SELECT
			COALESCE(NULLIF(s.nama_siswa, ''), NULLIF(u.nama, ''), latest.customer_name) AS student_name,
			COALESCE(NULLIF(s.asal_sekolah, ''), '') AS school_name,
			COALESCE(NULLIF(s.kelas, ''), '') AS class_name,
			latest.created_at,
			latest.status,
			latest.is_verified
		FROM (
			SELECT DISTINCT ON (pt.user_id)
				pt.user_id,
				pt.customer_name,
				pt.created_at,
				pt.status,
				COALESCE(pt.is_verified, FALSE) AS is_verified
			FROM payment_transactions pt
			WHERE pt.status IN ('success', 'pending')
			ORDER BY pt.user_id, pt.created_at DESC
		) latest
		LEFT JOIN users u ON u.id = latest.user_id
		LEFT JOIN siswa s ON s.user_id = latest.user_id
		WHERE latest.is_verified = FALSE
		ORDER BY latest.created_at DESC
		LIMIT 5`,
	)
	if err == nil {
		defer rows.Close()
		items := make([]DashboardPendingItem, 0)
		for rows.Next() {
			item := DashboardPendingItem{}
			var rawStatus string
			var isVerified bool
			if scanErr := rows.Scan(
				&item.StudentName,
				&item.SchoolName,
				&item.ClassName,
				&item.Date,
				&rawStatus,
				&isVerified,
			); scanErr != nil {
				continue
			}
			item.Status = mapVerificationStatus(rawStatus, isVerified)
			items = append(items, item)
		}
		summary.PendingItems = items
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Admin dashboard summary retrieved",
		"data":    summary,
	})
}
