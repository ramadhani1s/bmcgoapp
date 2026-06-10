package handlers

import (
	"bmcgoapp-backend/config"
	"context"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// GET semua olimpiade untuk siswa
func GetOlimpiadeSiswa(c *gin.Context) {
	status := c.Query("status") // "tersedia" atau "selesai"

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
			o.id, o.nama, o.class_level, o.lokasi, to_char(o.tanggal, 'YYYY-MM-DD') as tanggal,
			o.total_questions, o.category_questions,
			COALESCE(m.nama_mentor, 'Mentor BMC') AS mentor_nama,
			po.skor, po.ranking, po.jawaban_benar, po.jawaban_salah, po.tidak_dijawab,
			CASE WHEN po.selesai = true THEN 'selesai' ELSE 'tersedia' END as status_pengerjaan
		FROM olimpiade o
		LEFT JOIN mentor m ON m.id = o.mentor_id
		LEFT JOIN peserta_olimpiade po ON po.olimpiade_id = o.id AND po.siswa_id = $1
	`

	if status == "selesai" {
		query += " WHERE po.selesai = true ORDER BY o.tanggal DESC"
	} else if status == "tersedia" {
		query += " WHERE (po.id IS NULL OR po.selesai = false) ORDER BY o.tanggal DESC"
	} else {
		query += " ORDER BY o.tanggal DESC"
	}

	rows, err := config.DB.Query(context.Background(), query, siswaID)
	if err != nil {
		log.Println("Gagal query olimpiade:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil olimpiade"})
		return
	}
	defer rows.Close()

	type OlimpiadeItem struct {
		ID                int        `json:"id"`
		Nama              *string    `json:"nama"`
		ClassLevel        *string    `json:"class_level"`
		Lokasi            *string    `json:"lokasi"`
		Tanggal           *string    `json:"tanggal"`
		TotalQuestions    *int       `json:"total_questions"`
		CategoryQuestions string     `json:"category_questions"`
		MentorNama        *string    `json:"mentor_nama"`
		Skor              *int       `json:"skor"`
		Ranking           *int       `json:"ranking"`
		JawabanBenar      *int       `json:"jawaban_benar"`
		JawabanSalah      *int       `json:"jawaban_salah"`
		TidakDijawab      *int       `json:"tidak_dijawab"`
		Status            *string    `json:"status"`
	}

	var list []OlimpiadeItem
	for rows.Next() {
		var item OlimpiadeItem
		var catQuestions []byte
		if err := rows.Scan(
			&item.ID, &item.Nama, &item.ClassLevel, &item.Lokasi, &item.Tanggal,
			&item.TotalQuestions, &catQuestions, &item.MentorNama,
			&item.Skor, &item.Ranking, &item.JawabanBenar, &item.JawabanSalah, &item.TidakDijawab, &item.Status,
		); err != nil {
			log.Println("Gagal scan olimpiade siswa:", err)
			continue
		}
		item.CategoryQuestions = string(catQuestions)
		list = append(list, item)
	}

	if list == nil {
		list = []OlimpiadeItem{}
	}

	c.JSON(http.StatusOK, gin.H{"message": "OK", "data": list})
}

// GET soal olimpiade
func GetSoalOlimpiade(c *gin.Context) {
	olimpiadeIDStr := c.Param("id")
	review := c.Query("review") == "true"

	olimpiadeID, err := strconv.Atoi(olimpiadeIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	query := `
		SELECT id, pertanyaan, pilihan_a, pilihan_b, pilihan_c, pilihan_d, pilihan_e
	`
	if review {
		query += `, jawaban, pembahasan`
	}
	query += ` FROM olimpiade_soal WHERE kompetisi_id = $1 ORDER BY id`

	rows, err := config.DB.Query(context.Background(), query, olimpiadeID)

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
		Jawaban    string `json:"jawaban,omitempty"`
		Pembahasan string `json:"pembahasan,omitempty"`
	}

	var soalList []SoalItem
	for rows.Next() {
		var s SoalItem
		if review {
			if err := rows.Scan(&s.ID, &s.Pertanyaan, &s.PilihanA, &s.PilihanB, &s.PilihanC, &s.PilihanD, &s.PilihanE, &s.Jawaban, &s.Pembahasan); err != nil {
				continue
			}
		} else {
			if err := rows.Scan(&s.ID, &s.Pertanyaan, &s.PilihanA, &s.PilihanB, &s.PilihanC, &s.PilihanD, &s.PilihanE); err != nil {
				continue
			}
		}
		soalList = append(soalList, s)
	}

	if soalList == nil {
		soalList = []SoalItem{}
	}

	c.JSON(http.StatusOK, gin.H{"message": "OK", "data": soalList})
}

// POST submit jawaban olimpiade
func SubmitOlimpiade(c *gin.Context) {
	olimpiadeIDStr := c.Param("id")
	olimpiadeID, err := strconv.Atoi(olimpiadeIDStr)
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

	// Ambil semua soal beserta jawaban benar
	rows, err := config.DB.Query(context.Background(), `
		SELECT id, jawaban FROM olimpiade_soal WHERE kompetisi_id = $1
	`, olimpiadeID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal ambil soal"})
		return
	}
	defer rows.Close()

	type SoalJawaban struct {
		ID      int
		Jawaban string
	}

	var soalList []SoalJawaban
	for rows.Next() {
		var s SoalJawaban
		rows.Scan(&s.ID, &s.Jawaban)
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

	// Hitung ranking (berapa orang yang skornya lebih tinggi + 1)
	var ranking int
	config.DB.QueryRow(context.Background(),
		`SELECT COUNT(*) + 1 FROM peserta_olimpiade WHERE olimpiade_id = $1 AND skor > $2`,
		olimpiadeID, skor,
	).Scan(&ranking)

	// Hitung total peserta
	var totalPeserta int
	config.DB.QueryRow(context.Background(),
		`SELECT COUNT(*) FROM peserta_olimpiade WHERE olimpiade_id = $1`,
		olimpiadeID,
	).Scan(&totalPeserta)

	// Insert atau update peserta_olimpiade
	_, err = config.DB.Exec(context.Background(), `
		INSERT INTO peserta_olimpiade (siswa_id, olimpiade_id, skor, ranking, jawaban_benar, jawaban_salah, tidak_dijawab, selesai)
		VALUES ($1, $2, $3, $4, $5, $6, $7, true)
		ON CONFLICT (siswa_id, olimpiade_id) DO UPDATE
		SET skor = $3, ranking = $4, jawaban_benar = $5, jawaban_salah = $6, tidak_dijawab = $7, selesai = true
	`, siswaID, olimpiadeID, skor, ranking, benar, salah, tidakDijawab)

	if err != nil {
		log.Println("Gagal insert peserta:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal simpan hasil"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Hasil berhasil disimpan",
		"data": gin.H{
			"skor":          skor,
			"ranking":       ranking,
			"total_peserta": totalPeserta + 1,
			"jawaban_benar": benar,
			"jawaban_salah": salah,
			"tidak_dijawab": tidakDijawab,
			"total_soal":    totalSoal,
		},
	})
}
