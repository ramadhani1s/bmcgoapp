package models

import "time"

type MateriPembelajaran struct {
	ID          int       `json:"id" db:"id"`
	MentorID    int       `json:"mentor_id" db:"mentor_id"`
	Title       string    `json:"title" db:"title"`
	Description string    `json:"description" db:"description"`
	FilePath    string    `json:"file_path" db:"file_path"`
	FileType    string    `json:"file_type" db:"file_type"`
	FileSize    int64     `json:"file_size" db:"file_size"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}
