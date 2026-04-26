package services

import (
	"context"
	"errors"
	"strings"

	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"

	"golang.org/x/crypto/bcrypt"
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
		SELECT
			id,
			COALESCE(NULLIF(nama, ''), NULLIF(username, ''), 'User') AS nama,
			COALESCE(NULLIF(email, ''), username) AS email,
			password,
			COALESCE(role_id, 0) AS role_id
		FROM users
		WHERE
			LOWER(COALESCE(NULLIF(email, ''), username)) = LOWER($1)
			OR LOWER(username) = LOWER($1)
			OR LOWER(email) = LOWER($1)
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

	passwordMatched := false

	// Verify bcrypt hash first; fallback to legacy plain-text match for old rows.
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err == nil || user.Password == password {
		passwordMatched = true
	}

	// Legacy fallback: some old mentor data stores password in mentor table.
	if !passwordMatched {
		var mentorPassword string
		mentorErr := config.DB.QueryRow(
			context.Background(),
			`SELECT password FROM mentor WHERE user_id = $1 AND LOWER(email) = LOWER($2) LIMIT 1`,
			user.ID,
			email,
		).Scan(&mentorPassword)

		if mentorErr == nil {
			if bcrypt.CompareHashAndPassword([]byte(mentorPassword), []byte(password)) == nil || mentorPassword == password {
				passwordMatched = true
				if user.RoleID == 0 {
					user.RoleID = 2
				}
			}
		}
	}

	if !passwordMatched {
		return nil, errors.New("password salah")
	}

	if user.RoleID == 0 {
		user.RoleID = 3
	}

	user.Password = ""

	return &user, nil
}

// ===================================
// REGISTER
// ===================================
func Register(user models.User) error {
	// Hash password sebelum disimpan
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		return errors.New("gagal hash password")
	}

	query := `
		INSERT INTO users
		(nama,email,password,role_id)
		VALUES ($1,$2,$3,$4)
	`

	_, err = config.DB.Exec(
		context.Background(),
		query,
		user.Nama,
		user.Email,
		string(hashedPassword),
		user.RoleID,
	)

	return err
}
