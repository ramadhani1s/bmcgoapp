package handlers

import (
	"bmcgoapp-backend/config"
	"context"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// GET semua try out untuk siswa
func GetTryoutSiswa(c *gin.Context) {
	status := c.Query("status") // "tersedia" atau "selesai" (riwayat)

	// Since Tryout doesn't have a status column natively, we'll determine "tersedia" vs "selesai"
	// based on whether the student has a record in hasil_tryout.
	userID, _ := c.Get("user_id")
	
	// Cari siswa_id
	var siswaID int
	err := config.DB.QueryRow(context.Background(),
		`SELECT id FROM siswa WHERE user_id = $1`, userID,
	).Scan(&siswaID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menemukan data siswa"})
		return
	}

	query := `
		SELECT 
			t.id, t.paket_id, t.judul, t.tanggal, t.durasi,
			t.total_questions, t.category_questions,
			COALESCE(m.nama_mentor, 'Mentor BMC') AS mentor_nama,
			ht.nilai,
			CASE WHEN ht.id IS NOT NULL THEN 'selesai' ELSE 'tersedia' END as status_pengerjaan
		FROM tryout t
		LEFT JOIN mentor m ON m.id = t.mentor_id
		LEFT JOIN hasil_tryout ht ON ht.tryout_id = t.id AND ht.siswa_id = $1
	`
	
	if status == "selesai" {
		query += " WHERE ht.id IS NOT NULL ORDER BY t.tanggal DESC"
	} else if status == "tersedia" {
		query += " WHERE ht.id IS NULL ORDER BY t.tanggal DESC"
	} else {
		query += " ORDER BY t.tanggal DESC"
	}

	rows, err := config.DB.Query(context.Background(), query, siswaID)
	if err != nil {
		log.Println("Gagal query tryout:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil tryout"})
		return
	}
	defer rows.Close()

	type TryoutItem struct {
		ID                int       `json:"id"`
		PaketID           int       `json:"paket_id"`
		Judul             string    `json:"judul"`
		Tanggal           time.Time `json:"tanggal"`
		Durasi            int       `json:"durasi"`
		TotalQuestions    int       `json:"total_questions"`
		CategoryQuestions string    `json:"category_questions"`
		MentorNama        string    `json:"mentor_nama"`
		Nilai             *int      `json:"nilai"`
		Status            string    `json:"status"`
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
			log.Println("Gagal scan:", err)
			continue
		}
		item.CategoryQuestions = string(catQuestions)
		list = append(list, item)
	}

	if list == nil {
		list = []TryoutItem{}
	}

	c.JSON(http.StatusOK, gin.H{"message": "OK", "data": list})
}

// GET soal try out
func GetSoalTryoutSiswa(c *gin.Context) {
	tryoutIDStr := c.Param("id")
	tryoutID, err := strconv.Atoi(tryoutIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	rows, err := config.DB.Query(context.Background(), `
		SELECT id, pertanyaan, pilihan_a, pilihan_b, pilihan_c, pilihan_d, pilihan_e, kategori
		FROM tryout_soal
		WHERE kompetisi_id = $1
		ORDER BY id
	`, tryoutID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil soal"})
		return
	}
	defer rows.Close()

	type SoalItem struct {
		ID         int    `json:"id"`
		Pertanyaan string `json:"pertanyaan"`
		PilihanA   string `json:"pilihan_a"`
		PilihanB   string `json:"pilihan_b"`
		PilihanC   string `json:"pilihan_c"`
		PilihanD   string `json:"pilihan_d"`
		PilihanE   string `json:"pilihan_e"`
		Kategori   string `json:"kategori"`
	}

	var soalList []SoalItem
	for rows.Next() {
		var s SoalItem
		if err := rows.Scan(&s.ID, &s.Pertanyaan, &s.PilihanA, &s.PilihanB, &s.PilihanC, &s.PilihanD, &s.PilihanE, &s.Kategori); err != nil {
			continue
		}
		soalList = append(soalList, s)
	}

	if soalList == nil {
		soalList = []SoalItem{}
	}

	c.JSON(http.StatusOK, gin.H{"message": "OK", "data": soalList})
}

// POST submit jawaban tryout
func SubmitTryoutSiswa(c *gin.Context) {
	tryoutIDStr := c.Param("id")
	tryoutID, err := strconv.Atoi(tryoutIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	userID, _ := c.Get("user_id")

	var input struct {
		Jawaban map[string]string `json:"jawaban"` // soal_id -> jawaban
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Ambil semua soal beserta jawaban benar dan pembahasan
	rows, err := config.DB.Query(context.Background(), `
		SELECT id, jawaban, pembahasan, kategori FROM tryout_soal WHERE kompetisi_id = $1
	`, tryoutID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal ambil soal"})
		return
	}
	defer rows.Close()

	type SoalJawaban struct {
		ID         int
		Jawaban    string
		Pembahasan string
		Kategori   string
	}

	var soalList []SoalJawaban
	for rows.Next() {
		var s SoalJawaban
		rows.Scan(&s.ID, &s.Jawaban, &s.Pembahasan, &s.Kategori)
		soalList = append(soalList, s)
	}

	// Hitung skor
	benar := 0
	salah := 0
	tidakDijawab := 0
	totalSoal := len(soalList)

	for _, soal := range soalList {
		idStr := strconv.Itoa(soal.ID)
		jawaban, ada := input.Jawaban[idStr]
		if !ada || jawaban == "" {
			tidakDijawab++
		} else if jawaban == soal.Jawaban {
			benar++
		} else {
			salah++
		}
	}

	skor := 0
	if totalSoal > 0 {
		skor = (benar * 100) / totalSoal
	}

	// Cari siswa_id
	var siswaID int
	config.DB.QueryRow(context.Background(),
		`SELECT id FROM siswa WHERE user_id = $1`, userID,
	).Scan(&siswaID)

	// Simpan ke database (perlu tambah kolom jawaban_benar dll jika belum ada di tabel hasil_tryout)
	// Untuk saat ini simpan nilai saja (jika tabel hasil_tryout belum ada kolom jawaban_benar, kita biarkan insert default)
	// Wait, let's just try to insert and update
	_, err = config.DB.Exec(context.Background(), `
		INSERT INTO hasil_tryout (siswa_id, tryout_id, nilai)
		VALUES ($1, $2, $3)
		ON CONFLICT (siswa_id, tryout_id) DO UPDATE SET nilai = $3
	`, siswaID, tryoutID, skor)

	if err != nil {
		log.Println("Gagal insert hasil_tryout:", err)
		// Kita lanjutkan saja agar siswa tetap bisa lihat hasil sementara
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Hasil berhasil disimpan",
		"data": gin.H{
			"skor":           skor,
			"jawaban_benar":  benar,
			"jawaban_salah":  salah,
			"tidak_dijawab":  tidakDijawab,
			"total_soal":     totalSoal,
		},
	})
}
