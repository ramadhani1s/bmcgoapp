package services

import (
	"context"
	"errors"
	"fmt"
	"log"
	"regexp"
	"strings"

	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"

	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

func verifyPassword(ctx context.Context, storedPassword, inputPassword string, upgradeQuery string, upgradeArgs ...any) error {
	if err := bcrypt.CompareHashAndPassword([]byte(storedPassword), []byte(inputPassword)); err == nil {
		return nil
	}

	if storedPassword == inputPassword {
		newHash, hashErr := bcrypt.GenerateFromPassword([]byte(inputPassword), bcrypt.DefaultCost)
		if hashErr != nil {
			return errors.New("gagal memproses password")
		}

		if upgradeQuery != "" {
			args := append([]any{string(newHash)}, upgradeArgs...)
			if _, err := config.DB.Exec(ctx, upgradeQuery, args...); err != nil {
				log.Printf("warning: gagal upgrade password: %v", err)
			}
		}

		return nil
	}

	return errors.New("email atau password salah")
}

// Register mendaftarkan user siswa baru.
func Register(user models.User) error {
	if err := validateRegisterInput(user); err != nil {
		return err
	}

	user.Email = strings.ToLower(strings.TrimSpace(user.Email))
	user.Nama = strings.TrimSpace(user.Nama)

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		return errors.New("gagal hash password")
	}

	if user.RoleID == 0 {
		user.RoleID = 3
	}

	query := `
		INSERT INTO users (role_id, username, password, status)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`

	var userID int
	err = config.DB.QueryRow(
		context.Background(),
		query,
		user.RoleID,
		user.Email,
		string(hashedPassword),
		"aktif",
	).Scan(&userID)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate key") {
			return errors.New("email sudah terdaftar")
		}
		return fmt.Errorf("gagal menyimpan user: %w", err)
	}

	siswaQuery := `
		INSERT INTO siswa (user_id, nama_siswa, kelas, asal_sekolah, no_wa, alamat)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	_, err = config.DB.Exec(
		context.Background(),
		siswaQuery,
		userID,
		user.Nama,
		user.Kelas,
		user.AsalSekolah,
		user.WhatsApp,
		user.Alamat,
	)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate key") {
			return errors.New("email sudah terdaftar")
		}
		return fmt.Errorf("gagal menyimpan siswa: %w", err)
	}

	return nil
}

// Login memvalidasi kredensial user/admin dan mengembalikan profil.
func Login(email, password string) (*models.User, error) {
	if strings.TrimSpace(email) == "" || strings.TrimSpace(password) == "" {
		return nil, errors.New("email dan password harus diisi")
	}

	email = strings.ToLower(strings.TrimSpace(email))

	// Temporary mentor fallback account for website development.
	if email == "mentor@bmc.local" && password == "mentor123" {
		return &models.User{
			ID:       999999,
			Nama:     "Mentor Sementara",
			Email:    "mentor@bmc.local",
			RoleID:   2,
			Status:   "aktif",
			Password: "",
		}, nil
	}

	user := &models.User{}
	queryUser := `
		SELECT
			u.id,
			COALESCE(s.nama_siswa, m.nama_mentor, u.username),
			u.username,
			u.password,
			u.role_id,
			u.status,
			COALESCE(s.id, 0) AS siswa_id,
			COALESCE(s.kelas, ''),
			COALESCE(s.asal_sekolah, ''),
			COALESCE(s.no_wa, ''),
			COALESCE(s.alamat, '')
		FROM users u
		LEFT JOIN siswa s ON s.user_id = u.id
		LEFT JOIN mentor m ON m.user_id = u.id
		WHERE LOWER(u.username) = LOWER($1)
	`

	err := config.DB.QueryRow(context.Background(), queryUser, email).Scan(
		&user.ID,
		&user.Nama,
		&user.Email,
		&user.Password,
		&user.RoleID,
		&user.Status,
		&user.SiswaID,
		&user.Kelas,
		&user.AsalSekolah,
		&user.WhatsApp,
		&user.Alamat,
	)

	if err != nil {
		if !errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("gagal memproses login")
		}

		queryAdmin := `
			SELECT
				a.id,
				a.nama,
				a.email,
				a.password,
				1 AS role_id,
				'aktif' AS status,
				0 AS siswa_id,
				'' AS kelas,
				'' AS asal_sekolah,
				'' AS no_wa,
				'' AS alamat
			FROM admin a
			WHERE LOWER(a.email) = LOWER($1)
		`

		err = config.DB.QueryRow(context.Background(), queryAdmin, email).Scan(
			&user.ID,
			&user.Nama,
			&user.Email,
			&user.Password,
			&user.RoleID,
			&user.Status,
			&user.SiswaID,
			&user.Kelas,
			&user.AsalSekolah,
			&user.WhatsApp,
			&user.Alamat,
		)
		if err != nil {
			return nil, errors.New("email atau password salah")
		}
	}

	upgradeQuery := `UPDATE users SET password = $1 WHERE id = $2`
	if user.RoleID == 1 {
		upgradeQuery = `UPDATE admin SET password = $1 WHERE id = $2`
	}

	if err := verifyPassword(context.Background(), user.Password, password, upgradeQuery, user.ID); err != nil {
		return nil, errors.New("email atau password salah")
	}

	user.Password = ""
	return user, nil
}

func validateRegisterInput(user models.User) error {
	nama := strings.TrimSpace(user.Nama)
	if nama == "" {
		return errors.New("nama tidak boleh kosong")
	}
	if len(nama) < 3 {
		return errors.New("nama minimal 3 karakter")
	}
	if len(nama) > 100 {
		return errors.New("nama maksimal 100 karakter")
	}

	email := strings.TrimSpace(user.Email)
	if email == "" {
		return errors.New("email tidak boleh kosong")
	}

	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(email) {
		return errors.New("format email tidak valid")
	}

	if len(user.Password) == 0 {
		return errors.New("password tidak boleh kosong")
	}
	if len(user.Password) < 6 {
		return errors.New("password minimal 6 karakter")
	}
	if len(user.Password) > 50 {
		return errors.New("password maksimal 50 karakter")
	}

	return nil
}
