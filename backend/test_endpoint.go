package main

import (
	"bmcgoapp-backend/config"
	"context"
	"encoding/json"
	"fmt"
	"log"
)

func main() {
	config.ConnectDB()

	// Ambil satu siswa sembarang
	var siswaID int
	err := config.DB.QueryRow(context.Background(), "SELECT id FROM siswa LIMIT 1").Scan(&siswaID)
	if err != nil {
		log.Fatalf("Gagal mendapat siswa: %v", err)
	}

	query := `
		SELECT 
			t.id, t.paket_id, t.judul, to_char(t.tanggal, 'YYYY-MM-DD') as tanggal, t.durasi,
			t.total_questions, t.category_questions,
			COALESCE(m.nama_mentor, 'Mentor BMC') AS mentor_nama,
			ht.nilai,
			CASE WHEN ht.id IS NOT NULL THEN 'selesai' ELSE 'tersedia' END as status_pengerjaan
		FROM tryout t
		LEFT JOIN mentor m ON m.id = t.mentor_id
		LEFT JOIN hasil_tryout ht ON ht.tryout_id = t.id AND ht.siswa_id = $1
		WHERE ht.id IS NULL ORDER BY t.tanggal DESC
	`

	rows, err := config.DB.Query(context.Background(), query, siswaID)
	if err != nil {
		log.Fatalf("Gagal query tryout: %v", err)
	}
	defer rows.Close()

	type TryoutItem struct {
		ID                int        `json:"id"`
		PaketID           *int       `json:"paket_id"`
		Judul             *string    `json:"judul"`
		Tanggal           *string    `json:"tanggal"`
		Durasi            *int       `json:"durasi"`
		TotalQuestions    *int       `json:"total_questions"`
		CategoryQuestions string     `json:"category_questions"`
		MentorNama        *string    `json:"mentor_nama"`
		Nilai             *int       `json:"nilai"`
		Status            *string    `json:"status"`
	}

	var list []TryoutItem
	for rows.Next() {
		var item TryoutItem
		var catQuestions []byte
		if err := rows.Scan(
			&item.ID, &item.PaketID, &item.Judul,
			&item.Tanggal, &item.Durasi,
			&item.TotalQuestions, &catQuestions, &item.MentorNama,
			&item.Nilai, &item.Status,
		); err != nil {
			log.Fatalf("Gagal scan tryout siswa: %v", err)
		}
		item.CategoryQuestions = string(catQuestions)
		list = append(list, item)
	}

	if list == nil {
		list = []TryoutItem{}
	}

	b, _ := json.MarshalIndent(list, "", "  ")
	fmt.Println(string(b))
}
