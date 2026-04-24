package services

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
)

func getMentorIDByUserID(userID int) (int, error) {
	var mentorID int
	err := config.DB.QueryRow(
		context.Background(),
		`SELECT id FROM mentor WHERE user_id = $1`,
		userID,
	).Scan(&mentorID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			fallbackErr := config.DB.QueryRow(
				context.Background(),
				`SELECT id FROM mentor ORDER BY id ASC LIMIT 1`,
			).Scan(&mentorID)
			if fallbackErr != nil {
				if errors.Is(fallbackErr, pgx.ErrNoRows) {
					return 0, errors.New("data mentor tidak ditemukan untuk user ini")
				}
				return 0, fallbackErr
			}
			return mentorID, nil
		}
		return 0, err
	}

	return mentorID, nil
}

func GetSoalLatihanByMentorUserID(userID int) ([]models.SoalLatihan, error) {
	mentorID, err := getMentorIDByUserID(userID)
	if err != nil {
		return nil, err
	}

	rows, err := config.DB.Query(
		context.Background(),
		`SELECT id, mentor_id, COALESCE(pertanyaan, ''), COALESCE(pilihan_a, ''), COALESCE(pilihan_b, ''), COALESCE(pilihan_c, ''), COALESCE(pilihan_d, ''), COALESCE(jawaban, '') FROM soal_latihan WHERE mentor_id = $1 ORDER BY id DESC`,
		mentorID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]models.SoalLatihan, 0)
	for rows.Next() {
		var item models.SoalLatihan
		if err := rows.Scan(
			&item.ID,
			&item.MentorID,
			&item.Pertanyaan,
			&item.PilihanA,
			&item.PilihanB,
			&item.PilihanC,
			&item.PilihanD,
			&item.Jawaban,
		); err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return items, nil
}

func CreateSoalLatihan(userID int, input models.SoalLatihan) (*models.SoalLatihan, error) {
	mentorID, err := getMentorIDByUserID(userID)
	if err != nil {
		return nil, err
	}

	if input.Pertanyaan == "" || input.Jawaban == "" {
		return nil, errors.New("pertanyaan dan jawaban wajib diisi")
	}

	created := &models.SoalLatihan{}
	err = config.DB.QueryRow(
		context.Background(),
		`INSERT INTO soal_latihan (mentor_id, pertanyaan, pilihan_a, pilihan_b, pilihan_c, pilihan_d, jawaban) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id, mentor_id, COALESCE(pertanyaan, ''), COALESCE(pilihan_a, ''), COALESCE(pilihan_b, ''), COALESCE(pilihan_c, ''), COALESCE(pilihan_d, ''), COALESCE(jawaban, '')`,
		mentorID,
		input.Pertanyaan,
		input.PilihanA,
		input.PilihanB,
		input.PilihanC,
		input.PilihanD,
		input.Jawaban,
	).Scan(
		&created.ID,
		&created.MentorID,
		&created.Pertanyaan,
		&created.PilihanA,
		&created.PilihanB,
		&created.PilihanC,
		&created.PilihanD,
		&created.Jawaban,
	)
	if err != nil {
		return nil, err
	}

	return created, nil
}

func UpdateSoalLatihan(userID, soalID int, input models.SoalLatihan) (*models.SoalLatihan, error) {
	mentorID, err := getMentorIDByUserID(userID)
	if err != nil {
		return nil, err
	}

	updated := &models.SoalLatihan{}
	err = config.DB.QueryRow(
		context.Background(),
		`UPDATE soal_latihan SET pertanyaan = $1, pilihan_a = $2, pilihan_b = $3, pilihan_c = $4, pilihan_d = $5, jawaban = $6 WHERE id = $7 AND mentor_id = $8 RETURNING id, mentor_id, COALESCE(pertanyaan, ''), COALESCE(pilihan_a, ''), COALESCE(pilihan_b, ''), COALESCE(pilihan_c, ''), COALESCE(pilihan_d, ''), COALESCE(jawaban, '')`,
		input.Pertanyaan,
		input.PilihanA,
		input.PilihanB,
		input.PilihanC,
		input.PilihanD,
		input.Jawaban,
		soalID,
		mentorID,
	).Scan(
		&updated.ID,
		&updated.MentorID,
		&updated.Pertanyaan,
		&updated.PilihanA,
		&updated.PilihanB,
		&updated.PilihanC,
		&updated.PilihanD,
		&updated.Jawaban,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("soal tidak ditemukan")
		}
		return nil, err
	}

	return updated, nil
}

func DeleteSoalLatihan(userID, soalID int) error {
	mentorID, err := getMentorIDByUserID(userID)
	if err != nil {
		return err
	}

	cmd, err := config.DB.Exec(
		context.Background(),
		`DELETE FROM soal_latihan WHERE id = $1 AND mentor_id = $2`,
		soalID,
		mentorID,
	)
	if err != nil {
		return err
	}

	if cmd.RowsAffected() == 0 {
		return errors.New("soal tidak ditemukan")
	}

	return nil
}
