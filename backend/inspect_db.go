package main

import (
	"bmcgoapp-backend/config"
	"context"
	"fmt"
	"log"
)

func main() {
	config.ConnectDB()

	query := `
		SELECT 
			t.id, t.paket_id, t.judul, to_char(t.tanggal, 'YYYY-MM-DD') as tanggal, t.durasi,
			t.total_questions, t.category_questions,
			COALESCE(m.nama_mentor, 'Mentor BMC') AS mentor_nama
		FROM tryout t
		LEFT JOIN mentor m ON m.id = t.mentor_id
	`
	rows, err := config.DB.Query(context.Background(), query)
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	for rows.Next() {
		var id int
		var paketID *int
		var judul *string
		var tanggal *string
		var durasi *int
		var totalQuestions *int
		var categoryQuestions []byte
		var mentorNama *string

		if err := rows.Scan(
			&id, &paketID, &judul, &tanggal, &durasi,
			&totalQuestions, &categoryQuestions, &mentorNama,
		); err != nil {
			fmt.Printf("Gagal scan row: %v\n", err)
			continue
		}

		fmt.Printf("ID: %d, Paket: %v, Judul: %v, Tanggal: %v, Durasi: %v, TotalQ: %v, Mentor: %v, Cat: %s\n",
			id, valOrNil(paketID), valOrNilStr(judul), valOrNilStr(tanggal), valOrNil(durasi), valOrNil(totalQuestions), valOrNilStr(mentorNama), string(categoryQuestions))
	}
}

func valOrNil(p *int) string {
	if p == nil {
		return "NULL"
	}
	return fmt.Sprintf("%d", *p)
}

func valOrNilStr(p *string) string {
	if p == nil {
		return "NULL"
	}
	return *p
}
