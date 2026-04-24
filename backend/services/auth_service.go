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
				log.Printf("⚠️ Gagal upgrade password: %v\n", err)
			}
		}

		return nil
	}

	return errors.New("email atau password salah")
}

// Register - Mendaftarkan user baru
func Register(user models.User) error {
	// 1️⃣ Validasi input
	if err := validateRegisterInput(user); err != nil {
		return err
	}

	// 2️⃣ Normalisasi email dan nama
	user.Email = strings.ToLower(strings.TrimSpace(user.Email))
	user.Nama = strings.TrimSpace(user.Nama)

	log.Printf("📝 Register - Username: '%s', Nama: '%s'\n", user.Email, user.Nama)

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

	// 5️⃣ Insert ke table users
	queryWithUsername := `
	INSERT INTO users (role_id, nama, email, username, password, status)
	VALUES ($1, $2, $3, $4, $5, $6)
	RETURNING id
	`

	queryWithoutUsername := `
	INSERT INTO users (role_id, nama, email, password, status)
	VALUES ($1, $2, $3, $4, $5)
	RETURNING id
	`

	username := user.Email

	var userID int
	err = config.DB.QueryRow(
		context.Background(),
		queryWithUsername,
		user.RoleID,
		user.Nama,
		user.Email,
		username,
		string(hashedPassword),
		"nonaktif",
	).Scan(&userID)

	if err != nil {
		log.Printf("⚠️ Insert users (with username) error: %v\n", err)
	}

	if err != nil && strings.Contains(err.Error(), `column "username" of relation "users" does not exist`) {
		err = config.DB.QueryRow(
			context.Background(),
			queryWithoutUsername,
			user.RoleID,
			user.Nama,
			user.Email,
			string(hashedPassword),
			"nonaktif",
		).Scan(&userID)
	}

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
		return fmt.Errorf("gagal menyimpan user: %w", err)
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

	user := &models.User{}
	email = strings.ToLower(strings.TrimSpace(email))

	log.Printf("🔍 Login attempt - Email: '%s'\n", email)

	queryUser := `
	SELECT
		u.id,
		COALESCE(s.nama_siswa, u.nama),
		u.email,
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
	WHERE u.email = $1
	`

	err := config.DB.QueryRow(context.Background(), queryUser, email).
		Scan(&user.ID, &user.Nama, &user.Email, &user.Password, &user.RoleID, &user.Status, &user.SiswaID, &user.Kelas, &user.AsalSekolah, &user.WhatsApp, &user.Alamat)

	if err != nil {
		log.Printf("ℹ️ User tidak ditemukan di tabel users, coba fallback ke admin: %s (Error: %v)\n", email, err)

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
		WHERE a.email = $1
		`

		err = config.DB.QueryRow(context.Background(), queryAdmin, email).
			Scan(&user.ID, &user.Nama, &user.Email, &user.Password, &user.RoleID, &user.Status, &user.SiswaID, &user.Kelas, &user.AsalSekolah, &user.WhatsApp, &user.Alamat)
		if err != nil {
			log.Printf("❌ Admin not found in DB: %s (Error: %v)\n", email, err)
			return nil, errors.New("email atau password salah")
		}
	}

	log.Printf("✅ User found in DB: ID=%d, Email=%s, Hash length=%d\n", user.ID, user.Email, len(user.Password))

	upgradeQuery := `UPDATE users SET password = $1 WHERE id = $2`
	if user.RoleID == 1 {
		upgradeQuery = `UPDATE admin SET password = $1 WHERE id = $2`
	}

	err = verifyPassword(context.Background(), user.Password, password, upgradeQuery, user.ID)
	if err != nil {
		log.Printf("❌ Password mismatch for: %s (Error: %v)\n", email, err)
		return nil, errors.New("email atau password salah")
	}

	// Clear password dari response (jangan return password hash)
	user.Password = ""

	log.Printf("✅ User login successfully: ID=%d, Email=%s\n", user.ID, user.Email)
	return user, nil
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
