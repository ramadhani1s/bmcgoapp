package models

import "time"

type Pengumuman struct {
	ID        int       `json:"id"`
	AdminID   int       `json:"admin_id"`
	Judul     string    `json:"judul"`
	Isi       string    `json:"isi"`
	CreatedAt time.Time `json:"created_at"`
}

type CreatePengumumanRequest struct {
	Judul string `json:"judul" binding:"required"`
	Isi   string `json:"isi" binding:"required"`
}

type UpdatePengumumanRequest struct {
	Judul string `json:"judul"`
	Isi   string `json:"isi"`
}
