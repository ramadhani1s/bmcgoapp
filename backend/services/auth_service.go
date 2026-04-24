package services

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
	"context"
	"errors"
	"fmt"
	"log"
	"regexp"
	"strings"

	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

// Register - Mendaftarkan user baru
func Register(user models.User) error {
	// 1️⃣ Validasi input
	if err := validateRegisterInput(user); err != nil {
		return err
	}

	// 2️⃣ Normalisasi email dan nama
	user.Email = strings.ToLower(strings.TrimSpace(user.Email))
	user.Nama = strings.TrimSpace(user.Nama)

	log.Printf("📝 Register - Email: '%s', Nama: '%s'\n", user.Email, user.Nama)

	// 3️⃣ Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		log.Println("❌ Bcrypt error:", err)
		return errors.New("gagal hash password")
	}
	log.Printf("📝 Password hash created: %s...\n", string(hashedPassword)[:20])

	// 4️⃣ Set default role siswa jika belum ada
	if user.RoleID == 0 {
		user.RoleID = 3
	}

	// 5️⃣ Insert ke table users (users table uses 'username', not email)
	query := `
	INSERT INTO users (role_id, username, password, status)
	VALUES ($1, $2, $3, $4)
	RETURNING id
	`

	var userID int
	err = config.DB.QueryRow(context.Background(),
		query,
		user.RoleID,
		user.Email, // gunakan email sebagai username
		string(hashedPassword),
		"aktif",
	).Scan(&userID)

	if err != nil {
		if strings.Contains(err.Error(), "duplicate key") {
			return errors.New("email sudah terdaftar")
		}
		log.Println("❌ Database error:", err)
		return fmt.Errorf("gagal menyimpan user: %w", err)
	}

	// 6️⃣ Insert ke table siswa
	siswaQuery := `
	INSERT INTO siswa (user_id, nama_siswa, kelas, asal_sekolah, no_wa, alamat)
	VALUES ($1, $2, $3, $4, $5, $6)
	`

	_, err = config.DB.Exec(context.Background(),
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
		log.Println("❌ Database error:", err)
		return fmt.Errorf("gagal menyimpan siswa: %w", err)
	}

	log.Printf("✅ User registered successfully: ID=%d, Email=%s\n", userID, user.Email)
	return nil
}

// Login - Login user dengan email dan password
func Login(email, password string) (*models.User, error) {
	// Validasi input
	if strings.TrimSpace(email) == "" || strings.TrimSpace(password) == "" {
		return nil, errors.New("email dan password harus diisi")
	}

	email = strings.ToLower(strings.TrimSpace(email))

	// Temporary mentor fallback account for website development.
	// Use this until admin creates a real mentor account.
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

	log.Printf("🔍 Login attempt - Email: '%s'\n", email)

	user, err := findUserFromAdminTable(email)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		log.Printf("❌ Failed querying admin table: %v\n", err)
		return nil, errors.New("gagal memproses login")
	}

	if errors.Is(err, pgx.ErrNoRows) {
		user, err = findUserFromUsersTable(email)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				log.Printf("❌ User not found in admin/users tables: %s\n", email)
				return nil, errors.New("email atau password salah")
			}
			log.Printf("❌ Failed querying users table: %v\n", err)
			return nil, errors.New("gagal memproses login")
		}
	} else if !verifyLoginPassword(user.Password, password) {
		// If admin exists but password mismatches, still try users table.
		user, err = findUserFromUsersTable(email)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				log.Printf(" Password mismatch for admin table account: %s\n", email)
				return nil, errors.New("email atau password salah")
			}
			log.Printf("Failed querying users table after admin mismatch: %v\n", err)
			return nil, errors.New("gagal memproses login")
		}
	}

	log.Printf("✅ User found in DB: ID=%d, Email=%s, Hash length=%d\n", user.ID, user.Email, len(user.Password))

	if !verifyLoginPassword(user.Password, password) {
		log.Printf("❌ Password mismatch for: %s\n", email)
		return nil, errors.New("email atau password salah")
	}

	// Clear password dari response (jangan return password hash)
	user.Password = ""

	log.Printf("✅ User login successfully: ID=%d, Email=%s\n", user.ID, user.Email)
	return user, nil
}

func findUserFromUsersTable(email string) (*models.User, error) {
	user := &models.User{}

	// users table menggunakan username; nama ditarik dari siswa/mentor jika tersedia.
	query := `
	SELECT
		u.id,
		COALESCE(s.nama_siswa, m.nama_mentor, u.username),
		u.username, -- gunakan username sebagai email untuk response
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
	WHERE LOWER(u.username) = $1
	`

	err := config.DB.QueryRow(context.Background(), query, email).
		Scan(
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
		return nil, err
	}

	return user, nil
}

func findUserFromAdminTable(email string) (*models.User, error) {
	user := &models.User{}

	var hasUserID bool
	err := config.DB.QueryRow(
		context.Background(),
		`SELECT EXISTS (
			SELECT 1
			FROM information_schema.columns
			WHERE table_name = 'admin' AND column_name = 'user_id'
		)`,
	).Scan(&hasUserID)
	if err != nil {
		return nil, err
	}

	query := `
	SELECT
		id,
		nama,
		email,
		password
	FROM admin
	WHERE LOWER(email) = $1
	`

	if hasUserID {
		query = `
		SELECT
			user_id AS id,
			nama,
			email,
			password
		FROM admin
		WHERE LOWER(email) = $1
		`
	}

	err = config.DB.QueryRow(context.Background(), query, email).
		Scan(&user.ID, &user.Nama, &user.Email, &user.Password)
	if err != nil {
		return nil, err
	}

	user.RoleID = 1
	user.Status = "aktif"

	return user, nil
}

func verifyLoginPassword(storedPassword, inputPassword string) bool {
	if err := bcrypt.CompareHashAndPassword([]byte(storedPassword), []byte(inputPassword)); err == nil {
		return true
	}

	return storedPassword == inputPassword
}

// validateRegisterInput - Validasi input register
func validateRegisterInput(user models.User) error {
	// Validasi nama
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

	// Validasi email
	email := strings.TrimSpace(user.Email)
	if email == "" {
		return errors.New("email tidak boleh kosong")
	}

	// Email regex validation
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(email) {
		return errors.New("format email tidak valid")
	}

	// Validasi password
	password := user.Password
	if len(password) == 0 {
		return errors.New("password tidak boleh kosong")
	}
	if len(password) < 6 {
		return errors.New("password minimal 6 karakter")
	}
	if len(password) > 50 {
		return errors.New("password maksimal 50 karakter")
	}

	return nil
}
