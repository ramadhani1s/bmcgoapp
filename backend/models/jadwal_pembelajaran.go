package models

import (
	//"time"
)

type Jadwal struct {
	ID            int     `json:"id"`
	PaketID       *int    `json:"paket_id"`
	MentorID      *int    `json:"mentor_id"`
	ClassLevel    *string `json:"class_level" db:"class_level"`
	MataPelajaran *string `json:"mata_pelajaran"`
	Hari          *string `json:"hari"`
	JamMulai      *string `json:"jam_mulai"`
	JamSelesai    *string `json:"jam_selesai"`
	WaktuMulai    *string `json:"waktu_mulai"`
	WaktuSelesai  *string `json:"waktu_selesai"`
	Mentor        *string `json:"mentor"`
	Ruang         *string `json:"ruang"`
}

type CreateJadwalRequest struct {
	PaketID       int    `json:"paket_id" binding:"required"`
	MentorID      int    `json:"mentor_id" binding:"required"`
	ClassLevel    string `json:"class_level"`
	MataPelajaran string `json:"mata_pelajaran"`
	Hari          string `json:"hari"`
	JamMulai      string `json:"jam_mulai" binding:"required"`
	JamSelesai    string `json:"jam_selesai" binding:"required"`
	Ruang         string `json:"ruang"`
}

type UpdateJadwalRequest struct {
	PaketID       *int    `json:"paket_id"`
	MentorID      *int    `json:"mentor_id"`
	ClassLevel    *string `json:"class_level"`
	MataPelajaran *string `json:"mata_pelajaran"`
	Hari          *string `json:"hari"`
	JamMulai      *string `json:"jam_mulai"`
	JamSelesai    *string `json:"jam_selesai"`
	Ruang         *string `json:"ruang"`
}
