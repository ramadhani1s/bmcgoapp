package models

import (
	"time"
)

type PaketLes struct {
	ID                  int        `json:"id"`
	NamaPaket           string     `json:"nama_paket"`
	HargaAwal           int64      `json:"harga_awal"`
	Diskon              int        `json:"diskon"`
	TanggalMulaiPromo   *time.Time `json:"tanggal_mulai_promo"`
	TanggalSelesaiPromo *time.Time `json:"tanggal_selesai_promo"`
	Deskripsi           string     `json:"deskripsi"`
	Durasi              int        `json:"durasi"`
	Status              string     `json:"status"`
	CreatedAt           time.Time  `json:"created_at"`
}

type CreatePaketLesRequest struct {
	NamaPaket           string  `json:"nama_paket" binding:"required"`
	HargaAwal           int64   `json:"harga_awal" binding:"required"`
	Diskon              int     `json:"diskon"`
	TanggalMulaiPromo   *string `json:"tanggal_mulai_promo"`
	TanggalSelesaiPromo *string `json:"tanggal_selesai_promo"`
	Deskripsi           string  `json:"deskripsi"`
	Durasi              int     `json:"durasi"`
	Status              string  `json:"status"`
}

type UpdatePaketLesRequest struct {
	NamaPaket           string  `json:"nama_paket"`
	HargaAwal           int64   `json:"harga_awal"`
	Diskon              int     `json:"diskon"`
	TanggalMulaiPromo   *string `json:"tanggal_mulai_promo"`
	TanggalSelesaiPromo *string `json:"tanggal_selesai_promo"`
	Deskripsi           string  `json:"deskripsi"`
	Durasi              int     `json:"durasi"`
	Status              string  `json:"status"`
}
