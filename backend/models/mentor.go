package models

type Mentor struct {
	MentorID     int    `json:"mentor_id"`
	UserID       int    `json:"user_id"`
	Email        string `json:"email"`
	NamaMentor   string `json:"nama_mentor"`
	Spesialisasi string `json:"spesialisasi"`
	Bio          string `json:"bio"`
	Status       string `json:"status"`
}
