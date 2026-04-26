package services

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

func CreateMentor(email, password, namaMentor, spesialisasi, bio string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	namaMentor = strings.TrimSpace(namaMentor)
	spesialisasi = strings.TrimSpace(spesialisasi)
	bio = strings.TrimSpace(bio)

	if email == "" || password == "" || namaMentor == "" {
		return errors.New("email, password, dan nama_mentor wajib diisi")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return errors.New("gagal hash password")
	}

	tx, err := config.DB.Begin(context.Background())
	if err != nil {
		return fmt.Errorf("gagal memulai transaksi: %w", err)
	}
	defer tx.Rollback(context.Background())

	var userID int
	err = tx.QueryRow(
		context.Background(),
		`INSERT INTO users (role_id, username, email, nama, password, status) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
		2,
		email,
		email,
		namaMentor,
		string(hashedPassword),
		"aktif",
	).Scan(&userID)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate") {
			return errors.New("email sudah terdaftar")
		}
		return fmt.Errorf("gagal membuat user mentor: %w", err)
	}

	_, err = tx.Exec(
		context.Background(),
		`INSERT INTO mentor (user_id, nama_mentor, spesialisasi, bio) VALUES ($1, $2, $3, $4)`,
		userID,
		namaMentor,
		spesialisasi,
		bio,
	)
	if err != nil {
		return fmt.Errorf("gagal menyimpan data mentor: %w", err)
	}

	if err := tx.Commit(context.Background()); err != nil {
		return fmt.Errorf("gagal commit transaksi: %w", err)
	}

	return nil
}

func GetMentors() ([]models.Mentor, error) {
	query := `
	SELECT
		m.id AS mentor_id,
		m.user_id,
		COALESCE(NULLIF(u.email, ''), u.username) AS email,
		m.nama_mentor,
		COALESCE(m.spesialisasi, '') AS spesialisasi,
		COALESCE(m.bio, '') AS bio,
		u.status::text AS status
	FROM mentor m
	INNER JOIN users u ON u.id = m.user_id
	ORDER BY m.id DESC
	`

	rows, err := config.DB.Query(context.Background(), query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	mentors := make([]models.Mentor, 0)
	for rows.Next() {
		var item models.Mentor
		if err := rows.Scan(
			&item.MentorID,
			&item.UserID,
			&item.Email,
			&item.NamaMentor,
			&item.Spesialisasi,
			&item.Bio,
			&item.Status,
		); err != nil {
			return nil, err
		}
		mentors = append(mentors, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return mentors, nil
}

func DeleteMentorByID(mentorID int) error {
	if mentorID <= 0 {
		return errors.New("mentor_id tidak valid")
	}

	var userID int
	err := config.DB.QueryRow(
		context.Background(),
		`SELECT user_id FROM mentor WHERE id = $1`,
		mentorID,
	).Scan(&userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return errors.New("mentor tidak ditemukan")
		}
		return err
	}

	_, err = config.DB.Exec(
		context.Background(),
		`DELETE FROM users WHERE id = $1`,
		userID,
	)
	if err != nil {
		return err
	}

	return nil
}
