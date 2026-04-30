package models

import (
	"time"
)

type Jadwal struct {
	ID            int       `json:"id"`
	PaketID       int       `json:"paket_id"`
	MentorID      int       `json:"mentor_id"`
	MataPelajaran string    `json:"mata_pelajaran"`
	Hari          string    `json:"hari"`
	JamMulai      time.Time `json:"jam_mulai"`
	JamSelesai    time.Time `json:"jam_selesai"`
	Ruang         string    `json:"ruang"`
}

type CreateJadwalRequest struct {
	PaketID       int    `json:"paket_id" binding:"required"`
	MentorID      int    `json:"mentor_id" binding:"required"`
	MataPelajaran string `json:"mata_pelajaran"`
	Hari          string `json:"hari"`
	JamMulai      string `json:"jam_mulai" binding:"required"`
	JamSelesai    string `json:"jam_selesai" binding:"required"`
	Ruang         string `json:"ruang"`
}

type UpdateJadwalRequest struct {
	PaketID       *int    `json:"paket_id"`
	MentorID      *int    `json:"mentor_id"`
	MataPelajaran *string `json:"mata_pelajaran"`
	Hari          *string `json:"hari"`
	JamMulai      *string `json:"jam_mulai"`
	JamSelesai    *string `json:"jam_selesai"`
	Ruang         *string `json:"ruang"`
}
