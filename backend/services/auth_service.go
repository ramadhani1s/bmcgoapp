package services

import (
	"context"
	"errors"
	"strings"

	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
)

// ===================================
// LOGIN
// ===================================
func Login(email string, password string) (*models.User, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	password = strings.TrimSpace(password)

	// LOGIN DEFAULT ADMIN
	if email == "bimbelbmc@gmail.com" && password == "BMC123" {
		return &models.User{
			ID:       1,
			Nama:     "Administrator BMC",
			Email:    "bimbelbmc@gmail.com",
			RoleID:   1,
			Status:   "aktif",
			Password: "",
		}, nil
	}

	// LOGIN DEFAULT MENTOR
	if email == "mentor@bmc.local" && password == "mentor123" {
		return &models.User{
			ID:       2,
			Nama:     "Mentor Sementara",
			Email:    "mentor@bmc.local",
			RoleID:   2,
			Status:   "aktif",
			Password: "",
		}, nil
	}

	var user models.User

	query := `
		SELECT id, nama, email, password, role_id
		FROM users
		WHERE LOWER(email)=LOWER($1)
		LIMIT 1
	`

	err := config.DB.QueryRow(
		context.Background(),
		query,
		email,
	).Scan(
		&user.ID,
		&user.Nama,
		&user.Email,
		&user.Password,
		&user.RoleID,
	)

	if err != nil {
		return nil, errors.New("email tidak ditemukan")
	}

	if user.Password != password {
		return nil, errors.New("password salah")
	}

	user.Password = ""

	return &user, nil
}

// ===================================
// REGISTER
// ===================================
func Register(user models.User) error {
	query := `
		INSERT INTO users
		(nama,email,password,role_id)
		VALUES ($1,$2,$3,$4)
	`

	_, err := config.DB.Exec(
		context.Background(),
		query,
		user.Nama,
		user.Email,
		user.Password,
		user.RoleID,
	)

	return err
}