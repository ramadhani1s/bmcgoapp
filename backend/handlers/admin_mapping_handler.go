package handlers

import (
	"bmcgoapp-backend/config"
	"context"
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type adminMappingItem struct {
	AdminID    int     `json:"admin_id"`
	AdminName  string  `json:"admin_name"`
	AdminEmail string  `json:"admin_email"`
	UserID     *int    `json:"user_id,omitempty"`
	UserName   *string `json:"user_name,omitempty"`
	UserEmail  *string `json:"user_email,omitempty"`
}

type updateAdminMappingRequest struct {
	UserID int `json:"user_id"`
}

type userOption struct {
	ID    int    `json:"id"`
	Nama  string `json:"nama"`
	Email string `json:"email"`
	Role  int    `json:"role_id"`
}

func GetAdminMappings(c *gin.Context) {
	rows, err := config.DB.Query(context.Background(), `
		SELECT
			a.id,
			a.nama,
			a.email,
			a.user_id,
			u.nama,
			u.email
		FROM admin a
		LEFT JOIN users u ON u.id = a.user_id
		ORDER BY a.id ASC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal mengambil mapping admin", "detail": err.Error()})
		return
	}
	defer rows.Close()

	items := make([]adminMappingItem, 0)
	for rows.Next() {
		var item adminMappingItem
		var userID sql.NullInt64
		var userName sql.NullString
		var userEmail sql.NullString
		if err := rows.Scan(&item.AdminID, &item.AdminName, &item.AdminEmail, &userID, &userName, &userEmail); err == nil {
			if userID.Valid {
				value := int(userID.Int64)
				item.UserID = &value
			}
			if userName.Valid {
				value := userName.String
				item.UserName = &value
			}
			if userEmail.Valid {
				value := userEmail.String
				item.UserEmail = &value
			}
			items = append(items, item)
		}
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Daftar mapping admin berhasil diambil", "data": items, "count": len(items)})
}

func GetUsersForMapping(c *gin.Context) {
	rows, err := config.DB.Query(context.Background(), `
		SELECT id, nama, email, role_id
		FROM users
		ORDER BY id ASC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal mengambil daftar user", "detail": err.Error()})
		return
	}
	defer rows.Close()

	items := make([]userOption, 0)
	for rows.Next() {
		var item userOption
		var nama sql.NullString
		var email sql.NullString
		var role sql.NullInt64
		if err := rows.Scan(&item.ID, &nama, &email, &role); err == nil {
			if nama.Valid {
				item.Nama = nama.String
			}
			if email.Valid {
				item.Email = email.String
			}
			if role.Valid {
				item.Role = int(role.Int64)
			}
			items = append(items, item)
		}
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Daftar user berhasil diambil", "data": items, "count": len(items)})
}

func SyncAdminMappings(c *gin.Context) {
	res, err := config.DB.Exec(context.Background(), `
		UPDATE admin a
		SET user_id = u.id
		FROM users u
		WHERE lower(trim(a.email)) = lower(trim(u.email))
			AND (a.user_id IS DISTINCT FROM u.id)
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal sinkron mapping admin", "detail": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Mapping admin berhasil disinkronkan", "updated": res.RowsAffected()})
}

func UpdateAdminMapping(c *gin.Context) {
	adminID, err := strconv.Atoi(c.Param("adminId"))
	if err != nil || adminID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Admin ID tidak valid"})
		return
	}

	var req updateAdminMappingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Request tidak valid", "detail": err.Error()})
		return
	}

	if req.UserID <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "User ID wajib diisi"})
		return
	}

	var exists bool
	err = config.DB.QueryRow(context.Background(), `SELECT EXISTS(SELECT 1 FROM users WHERE id = $1)`, req.UserID).Scan(&exists)
	if err != nil || !exists {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "User tidak ditemukan"})
		return
	}

	_, err = config.DB.Exec(context.Background(), `UPDATE admin SET user_id = $1 WHERE id = $2`, req.UserID, adminID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Gagal memperbarui mapping admin", "detail": err.Error()})
		return
	}

	// Keep the admin email aligned with the chosen user if it is currently blank or different by case/spacing.
	_, _ = config.DB.Exec(context.Background(), `
		UPDATE admin a
		SET email = COALESCE(NULLIF(a.email, ''), u.email), nama = COALESCE(NULLIF(a.nama, ''), u.nama)
		FROM users u
		WHERE a.id = $1 AND u.id = $2
	`, adminID, req.UserID)

	c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Mapping admin berhasil diperbarui", "data": gin.H{"admin_id": adminID, "user_id": req.UserID}})
}

func NormalizeAdminMappings() {
	_, _ = config.DB.Exec(context.Background(), `
		UPDATE admin a
		SET user_id = u.id
		FROM users u
		WHERE lower(trim(a.email)) = lower(trim(u.email))
	`)
}
