package models

type SoalLatihan struct {
	ID         int    `json:"id"`
	MentorID   int    `json:"mentor_id"`
	Pertanyaan string `json:"pertanyaan"`
	PilihanA   string `json:"pilihan_a"`
	PilihanB   string `json:"pilihan_b"`
	PilihanC   string `json:"pilihan_c"`
	PilihanD   string `json:"pilihan_d"`
	Jawaban    string `json:"jawaban"`
	Pembahasan string `json:"pembahasan"`
	Subject    string `json:"subject"`
	LatihanID  *int   `json:"latihan_id"`
}
