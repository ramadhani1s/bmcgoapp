package services

import (
	"bmcgoapp-backend/config"
	"bmcgoapp-backend/models"
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
)

// GetTryoutSoal retrieves all soal for a tryout by kompetisi_id
func GetTryoutSoal(kompetisiID int) ([]models.SoalKompetisi, error) {
	rows, err := config.DB.Query(
		context.Background(),
		`SELECT id, kompetisi_id, 'tryout' as tipe, COALESCE(pertanyaan, ''), COALESCE(pilihan_a, ''), COALESCE(pilihan_b, ''), COALESCE(pilihan_c, ''), COALESCE(pilihan_d, ''), COALESCE(pilihan_e, ''), COALESCE(jawaban, ''), COALESCE(pembahasan, ''), COALESCE(kategori, '') FROM tryout_soal WHERE kompetisi_id = $1 ORDER BY id DESC`,
		kompetisiID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]models.SoalKompetisi, 0)
	for rows.Next() {
		var item models.SoalKompetisi
		if err := rows.Scan(
			&item.ID,
			&item.KompetisiID,
			&item.Tipe,
			&item.Pertanyaan,
			&item.PilihanA,
			&item.PilihanB,
			&item.PilihanC,
			&item.PilihanD,
			&item.PilihanE,
			&item.Jawaban,
			&item.Pembahasan,
			&item.Kategori,
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

// GetOlimpiadseSoal retrieves all soal for olimpiade by kompetisi_id
func GetOlimpiadseSoal(kompetisiID int) ([]models.SoalKompetisi, error) {
	rows, err := config.DB.Query(
		context.Background(),
		`SELECT id, kompetisi_id, 'olimpiade' as tipe, COALESCE(pertanyaan, ''), COALESCE(pilihan_a, ''), COALESCE(pilihan_b, ''), COALESCE(pilihan_c, ''), COALESCE(pilihan_d, ''), COALESCE(pilihan_e, ''), COALESCE(jawaban, ''), COALESCE(pembahasan, ''), '' as kategori FROM olimpiade_soal WHERE kompetisi_id = $1 ORDER BY id DESC`,
		kompetisiID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]models.SoalKompetisi, 0)
	for rows.Next() {
		var item models.SoalKompetisi
		if err := rows.Scan(
			&item.ID,
			&item.KompetisiID,
			&item.Tipe,
			&item.Pertanyaan,
			&item.PilihanA,
			&item.PilihanB,
			&item.PilihanC,
			&item.PilihanD,
			&item.PilihanE,
			&item.Jawaban,
			&item.Pembahasan,
			&item.Kategori,
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

// CreateTryoutSoal creates a new tryout soal
func CreateTryoutSoal(input models.SoalKompetisi) (*models.SoalKompetisi, error) {
	if input.Pertanyaan == "" || input.Jawaban == "" || input.KompetisiID <= 0 {
		return nil, errors.New("pertanyaan, jawaban, dan kompetisi_id wajib diisi")
	}

	created := &models.SoalKompetisi{}
	err := config.DB.QueryRow(
		context.Background(),
		`INSERT INTO tryout_soal (kompetisi_id, pertanyaan, pilihan_a, pilihan_b, pilihan_c, pilihan_d, pilihan_e, jawaban, pembahasan, kategori) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id, kompetisi_id, 'tryout' as tipe, COALESCE(pertanyaan, ''), COALESCE(pilihan_a, ''), COALESCE(pilihan_b, ''), COALESCE(pilihan_c, ''), COALESCE(pilihan_d, ''), COALESCE(pilihan_e, ''), COALESCE(jawaban, ''), COALESCE(pembahasan, ''), COALESCE(kategori, '')`,
		input.KompetisiID,
		input.Pertanyaan,
		input.PilihanA,
		input.PilihanB,
		input.PilihanC,
		input.PilihanD,
		input.PilihanE,
		input.Jawaban,
		input.Pembahasan,
		input.Kategori,
	).Scan(
		&created.ID,
		&created.KompetisiID,
		&created.Tipe,
		&created.Pertanyaan,
		&created.PilihanA,
		&created.PilihanB,
		&created.PilihanC,
		&created.PilihanD,
		&created.PilihanE,
		&created.Jawaban,
		&created.Pembahasan,
		&created.Kategori,
	)
	if err != nil {
		return nil, err
	}

	return created, nil
}

// UpdateTryoutSoal updates an existing tryout soal
func UpdateTryoutSoal(soalID int, input models.SoalKompetisi) (*models.SoalKompetisi, error) {
	updated := &models.SoalKompetisi{}
	err := config.DB.QueryRow(
		context.Background(),
		`UPDATE tryout_soal SET pertanyaan = $1, pilihan_a = $2, pilihan_b = $3, pilihan_c = $4, pilihan_d = $5, pilihan_e = $6, jawaban = $7, pembahasan = $8, kategori = $9 WHERE id = $10 RETURNING id, kompetisi_id, 'tryout' as tipe, COALESCE(pertanyaan, ''), COALESCE(pilihan_a, ''), COALESCE(pilihan_b, ''), COALESCE(pilihan_c, ''), COALESCE(pilihan_d, ''), COALESCE(pilihan_e, ''), COALESCE(jawaban, ''), COALESCE(pembahasan, ''), COALESCE(kategori, '')`,
		input.Pertanyaan,
		input.PilihanA,
		input.PilihanB,
		input.PilihanC,
		input.PilihanD,
		input.PilihanE,
		input.Jawaban,
		input.Pembahasan,
		input.Kategori,
		soalID,
	).Scan(
		&updated.ID,
		&updated.KompetisiID,
		&updated.Tipe,
		&updated.Pertanyaan,
		&updated.PilihanA,
		&updated.PilihanB,
		&updated.PilihanC,
		&updated.PilihanD,
		&updated.PilihanE,
		&updated.Jawaban,
		&updated.Pembahasan,
		&updated.Kategori,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("soal tidak ditemukan")
		}
		return nil, err
	}

	return updated, nil
}

// DeleteTryoutSoal deletes a tryout soal
func DeleteTryoutSoal(soalID int) error {
	result, err := config.DB.Exec(
		context.Background(),
		`DELETE FROM tryout_soal WHERE id = $1`,
		soalID,
	)
	if err != nil {
		return err
	}

	if result.RowsAffected() == 0 {
		return errors.New("soal tidak ditemukan")
	}

	return nil
}

// CreateOlimpiadseSoal creates a new olimpiade soal
func CreateOlimpiadseSoal(input models.SoalKompetisi) (*models.SoalKompetisi, error) {
	if input.Pertanyaan == "" || input.Jawaban == "" || input.KompetisiID <= 0 {
		return nil, errors.New("pertanyaan, jawaban, dan kompetisi_id wajib diisi")
	}

	created := &models.SoalKompetisi{}
	err := config.DB.QueryRow(
		context.Background(),
		`INSERT INTO olimpiade_soal (kompetisi_id, pertanyaan, pilihan_a, pilihan_b, pilihan_c, pilihan_d, pilihan_e, jawaban, pembahasan) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id, kompetisi_id, 'olimpiade' as tipe, COALESCE(pertanyaan, ''), COALESCE(pilihan_a, ''), COALESCE(pilihan_b, ''), COALESCE(pilihan_c, ''), COALESCE(pilihan_d, ''), COALESCE(pilihan_e, ''), COALESCE(jawaban, ''), COALESCE(pembahasan, ''), ''`,
		input.KompetisiID,
		input.Pertanyaan,
		input.PilihanA,
		input.PilihanB,
		input.PilihanC,
		input.PilihanD,
		input.PilihanE,
		input.Jawaban,
		input.Pembahasan,
	).Scan(
		&created.ID,
		&created.KompetisiID,
		&created.Tipe,
		&created.Pertanyaan,
		&created.PilihanA,
		&created.PilihanB,
		&created.PilihanC,
		&created.PilihanD,
		&created.PilihanE,
		&created.Jawaban,
		&created.Pembahasan,
		&created.Kategori,
	)
	if err != nil {
		return nil, err
	}

	return created, nil
}

// UpdateOlimpiadseSoal updates an existing olimpiade soal
func UpdateOlimpiadseSoal(soalID int, input models.SoalKompetisi) (*models.SoalKompetisi, error) {
	updated := &models.SoalKompetisi{}
	err := config.DB.QueryRow(
		context.Background(),
		`UPDATE olimpiade_soal SET pertanyaan = $1, pilihan_a = $2, pilihan_b = $3, pilihan_c = $4, pilihan_d = $5, pilihan_e = $6, jawaban = $7, pembahasan = $8 WHERE id = $9 RETURNING id, kompetisi_id, 'olimpiade' as tipe, COALESCE(pertanyaan, ''), COALESCE(pilihan_a, ''), COALESCE(pilihan_b, ''), COALESCE(pilihan_c, ''), COALESCE(pilihan_d, ''), COALESCE(pilihan_e, ''), COALESCE(jawaban, ''), COALESCE(pembahasan, ''), ''`,
		input.Pertanyaan,
		input.PilihanA,
		input.PilihanB,
		input.PilihanC,
		input.PilihanD,
		input.PilihanE,
		input.Jawaban,
		input.Pembahasan,
		soalID,
	).Scan(
		&updated.ID,
		&updated.KompetisiID,
		&updated.Tipe,
		&updated.Pertanyaan,
		&updated.PilihanA,
		&updated.PilihanB,
		&updated.PilihanC,
		&updated.PilihanD,
		&updated.PilihanE,
		&updated.Jawaban,
		&updated.Pembahasan,
		&updated.Kategori,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("soal tidak ditemukan")
		}
		return nil, err
	}

	return updated, nil
}

// DeleteOlimpiadseSoal deletes an olimpiade soal
func DeleteOlimpiadseSoal(soalID int) error {
	result, err := config.DB.Exec(
		context.Background(),
		`DELETE FROM olimpiade_soal WHERE id = $1`,
		soalID,
	)
	if err != nil {
		return err
	}

	if result.RowsAffected() == 0 {
		return errors.New("soal tidak ditemukan")
	}

	return nil
}
