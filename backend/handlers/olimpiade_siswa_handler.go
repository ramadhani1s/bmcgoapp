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

// GET semua olimpiade untuk siswa
func GetOlimpiadeSiswa(c *gin.Context) {
	status := c.Query("status")

	query := `
		SELECT 
			o.id, o.nama, o.mata_pelajaran, o.deskripsi,
			o.tanggal_mulai, o.tanggal_selesai, o.durasi,
			o.total_soal, o.status,
			COALESCE(m.nama_mentor, 'Mentor BMC') AS mentor_nama
		FROM olimpiade o
		LEFT JOIN mentor m ON m.id = o.mentor_id
	`

	var rows interface{}
	var err error

	if status != "" && status != "semua" {
		query += " WHERE o.status = $1 ORDER BY o.tanggal_mulai DESC"
		rows, err = config.DB.Query(context.Background(), query, status)
	} else {
		query += " ORDER BY o.tanggal_mulai DESC"
		rows, err = config.DB.Query(context.Background(), query)
	}

	if err != nil {
		log.Println("Gagal query olimpiade:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil olimpiade"})
		return
	}

	type OlimpiadeItem struct {
		ID             int       `json:"id"`
		Nama           string    `json:"nama"`
		MataPelajaran  string    `json:"mata_pelajaran"`
		Deskripsi      string    `json:"deskripsi"`
		TanggalMulai   time.Time `json:"tanggal_mulai"`
		TanggalSelesai time.Time `json:"tanggal_selesai"`
		Durasi         int       `json:"durasi"`
		TotalSoal      int       `json:"total_soal"`
		Status         string    `json:"status"`
		MentorNama     string    `json:"mentor_nama"`
	}

	pgxRows := rows.(interface {
		Next() bool
		Scan(...any) error
		Close()
	})
	defer pgxRows.Close()

	var list []OlimpiadeItem
	for pgxRows.Next() {
		var item OlimpiadeItem
		if err := pgxRows.Scan(
			&item.ID, &item.Nama, &item.MataPelajaran, &item.Deskripsi,
			&item.TanggalMulai, &item.TanggalSelesai, &item.Durasi,
			&item.TotalSoal, &item.Status, &item.MentorNama,
		); err != nil {
			log.Println("Gagal scan:", err)
			continue
		}
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
	olimpiadeID, err := strconv.Atoi(olimpiadeIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	rows, err := config.DB.Query(context.Background(), `
		SELECT id, pertanyaan, pilihan_a, pilihan_b, pilihan_c, pilihan_d, pilihan_e
		FROM soal_olimpiade
		WHERE olimpiade_id = $1
		ORDER BY id
	`, olimpiadeID)

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
	}

	var soalList []SoalItem
	for rows.Next() {
		var s SoalItem
		if err := rows.Scan(&s.ID, &s.Pertanyaan, &s.PilihanA, &s.PilihanB, &s.PilihanC, &s.PilihanD, &s.PilihanE); err != nil {
			continue
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
		SELECT id, jawaban FROM soal_olimpiade WHERE olimpiade_id = $1
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
			"skor":           skor,
			"ranking":        ranking,
			"total_peserta":  totalPeserta + 1,
			"jawaban_benar":  benar,
			"jawaban_salah":  salah,
			"tidak_dijawab":  tidakDijawab,
			"total_soal":     totalSoal,
		},
	})
}