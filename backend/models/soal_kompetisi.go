package models

type SoalKompetisi struct {
	ID          int    `json:"id"`
	KompetisiID int    `json:"kompetisi_id"`
	Tipe        string `json:"tipe"` // "tryout" atau "olimpiade"
	Pertanyaan  string `json:"pertanyaan"`
	PilihanA    string `json:"pilihan_a"`
	PilihanB    string `json:"pilihan_b"`
	PilihanC    string `json:"pilihan_c"`
	PilihanD    string `json:"pilihan_d"`
	PilihanE    string `json:"pilihan_e"`
	Jawaban     string `json:"jawaban"`
	Pembahasan  string `json:"pembahasan"`
	Kategori    string `json:"kategori"` // untuk tryout
}
