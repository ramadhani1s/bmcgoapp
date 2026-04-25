package services

import (
	"context"
	"errors"
	"log"
	"regexp"
	"strings"

	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"golang.org/x/crypto/bcrypt"
)

// ==================================================
// CHECK ERROR COLUMN
// ==================================================
func isUndefinedColumnError(err error) bool {
	var pgErr *pgconn.PgError

	if errors.As(err, &pgErr) {
		return pgErr.Code == "42703"
	}

	msg := strings.ToLower(err.Error())

	return strings.Contains(msg, "column") &&
		strings.Contains(msg, "does not exist")
}

// ==================================================
// CHECK ERROR TABLE
// ==================================================
func isSchemaMismatchError(err error) bool {
	if err == nil {
		return false
	}

	if isUndefinedColumnError(err) {
		return true
	}

	var pgErr *pgconn.PgError

	if errors.As(err, &pgErr) {
		return pgErr.Code == "42P01"
	}

	msg := strings.ToLower(err.Error())

	return strings.Contains(msg, "relation") &&
		strings.Contains(msg, "does not exist")
}

// ==================================================
// VERIFY PASSWORD
// ==================================================
func verifyPassword(
	ctx context.Context,
	storedPassword string,
	inputPassword string,
	upgradeQuery string,
	upgradeArgs ...any,
) error {
	storedPassword = strings.TrimSpace(storedPassword)
	inputPassword = strings.TrimSpace(inputPassword)

	// bcrypt
	if err := bcrypt.CompareHashAndPassword(
		[]byte(storedPassword),
		[]byte(inputPassword),
	); err == nil {
		return nil
	}

	// plaintext lama
	if storedPassword == inputPassword {
		newHash, hashErr := bcrypt.GenerateFromPassword(
			[]byte(inputPassword),
			bcrypt.DefaultCost,
		)

		if hashErr == nil && upgradeQuery != "" {
			args := append([]any{string(newHash)}, upgradeArgs...)

			_, err := config.DB.Exec(
				ctx,
				upgradeQuery,
				args...,
			)

			if err != nil {
				log.Println("upgrade password gagal:", err)
			}
		}

		return nil
	}

	return errors.New("password salah")
}

// ==================================================
// DEFAULT ADMIN
// ==================================================
func seedDefaultAdmin() {
	email := "bimbelbmc@gmail.com"

	var count int

	err := config.DB.QueryRow(
		context.Background(),
		`SELECT COUNT(*) FROM admin WHERE LOWER(email)=LOWER($1)`,
		email,
	).Scan(&count)

	if err != nil {
		return
	}

	if count > 0 {
		return
	}

	hash, _ := bcrypt.GenerateFromPassword(
		[]byte("BMC123"),
		bcrypt.DefaultCost,
	)

	_, _ = config.DB.Exec(
		context.Background(),
		`
		INSERT INTO admin
		(nama,email,password)
		VALUES ($1,$2,$3)
	`,
		"Administrator BMC",
		email,
		string(hash),
	)
}

// ==================================================
// REGISTER
// ==================================================
func Register(user models.User) error {
	if err := validateRegisterInput(user); err != nil {
		return err
	}

	user.Email = strings.ToLower(strings.TrimSpace(user.Email))
	user.Nama = strings.TrimSpace(user.Nama)

	if user.RoleID == 0 {
		user.RoleID = 3
	}

	hashedPassword, err := bcrypt.GenerateFromPassword(
		[]byte(user.Password),
		bcrypt.DefaultCost,
	)

	if err != nil {
		return errors.New("gagal hash password")
	}

	query := `
		INSERT INTO users
		(
			nama,
			email,
			password,
			role_id
		)
		VALUES ($1,$2,$3,$4)
		RETURNING id
	`

	var userID int

	err = config.DB.QueryRow(
		context.Background(),
		query,
		user.Nama,
		user.Email,
		string(hashedPassword),
		user.RoleID,
	).Scan(&userID)

	if err != nil {
		if strings.Contains(
			strings.ToLower(err.Error()),
			"duplicate",
		) {
			return errors.New("email sudah terdaftar")
		}

		return err
	}

	if user.RoleID == 3 {
		_, _ = config.DB.Exec(
			context.Background(),
			`
			INSERT INTO siswa
			(
				user_id,
				nama_siswa,
				kelas,
				asal_sekolah,
				no_wa,
				alamat
			)
			VALUES ($1,$2,$3,$4,$5,$6)
		`,
			userID,
			user.Nama,
			user.Kelas,
			user.AsalSekolah,
			user.WhatsApp,
			user.Alamat,
		)
	}

	return nil
}

// ==================================================
// LOGIN
// ==================================================
func Login(email string, password string) (*models.User, error) {
	if strings.TrimSpace(email) == "" ||
		strings.TrimSpace(password) == "" {
		return nil, errors.New("email dan password harus diisi")
	}

	email = strings.ToLower(strings.TrimSpace(email))
	password = strings.TrimSpace(password)

	// ==========================================
	// LOGIN DEFAULT ADMIN
	// ==========================================
	if email == "bimbelbmc@gmail.com" &&
		password == "BMC123" {
		return &models.User{
			ID:       1,
			Nama:     "Administrator BMC",
			Email:    "bimbelbmc@gmail.com",
			RoleID:   1,
			Status:   "aktif",
			Password: "",
		}, nil
	}

	// ==========================================
	// LOGIN DEFAULT MENTOR
	// ==========================================
	if email == "mentor@bmc.local" &&
		password == "mentor123" {
		return &models.User{
			ID:       999999,
			Nama:     "Mentor Sementara",
			Email:    "mentor@bmc.local",
			RoleID:   2,
			Status:   "aktif",
			Password: "",
		}, nil
	}

	// pastikan admin default ada di DB
	seedDefaultAdmin()

	user := &models.User{}

	// ==========================================
	// USERS TABLE
	// ==========================================
	queryUser := `
		SELECT
			id,
			nama,
			email,
			password,
			role_id
		FROM users
		WHERE LOWER(email)=LOWER($1)
		LIMIT 1
	`

	err := config.DB.QueryRow(
		context.Background(),
		queryUser,
		email,
	).Scan(
		&user.ID,
		&user.Nama,
		&user.Email,
		&user.Password,
		&user.RoleID,
	)

	// ==========================================
	// ADMIN TABLE
	// ==========================================
	if err != nil {
		queryAdmin := `
			SELECT
				id,
				nama,
				email,
				password,
				1 as role_id
			FROM admin
			WHERE LOWER(email)=LOWER($1)
			LIMIT 1
		`

		err = config.DB.QueryRow(
			context.Background(),
			queryAdmin,
			email,
		).Scan(
			&user.ID,
			&user.Nama,
			&user.Email,
			&user.Password,
			&user.RoleID,
		)

		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return nil, errors.New("email tidak ditemukan")
			}

			return nil, errors.New("gagal login")
		}
	}

	upgradeQuery := `
		UPDATE users
		SET password=$1
		WHERE id=$2
	`

	if user.RoleID == 1 {
		upgradeQuery = `
			UPDATE admin
			SET password=$1
			WHERE id=$2
		`
	}

	if err := verifyPassword(
		context.Background(),
		user.Password,
		password,
		upgradeQuery,
		user.ID,
	); err != nil {
		return nil, err
	}

	user.Password = ""

	return user, nil
}

// ==================================================
// VALIDASI REGISTER
// ==================================================
func validateRegisterInput(user models.User) error {
	nama := strings.TrimSpace(user.Nama)

	if nama == "" {
		return errors.New("nama tidak boleh kosong")
	}

	if len(nama) < 3 {
		return errors.New("nama minimal 3 karakter")
	}

	email := strings.TrimSpace(user.Email)

	if email == "" {
		return errors.New("email tidak boleh kosong")
	}

	emailRegex := regexp.MustCompile(
		`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`,
	)

	if !emailRegex.MatchString(email) {
		return errors.New("format email tidak valid")
	}

	pass := strings.TrimSpace(user.Password)

	if pass == "" {
		return errors.New("password tidak boleh kosong")
	}

	if len(pass) < 6 {
		return errors.New("password minimal 6 karakter")
	}

	if len(pass) > 50 {
		return errors.New("password maksimal 50 karakter")
	}

	return nil
}