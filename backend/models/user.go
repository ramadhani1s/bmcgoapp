package models

type User struct {
	ID          int    `json:"id"`
	Nama        string `json:"nama"`
	Email       string `json:"email"`
	Password    string `json:"password"`
	RoleID      int    `json:"role_id"`
	PhoneNumber string `json:"phone_number"`
	Status      string `json:"status"`
	Kelas       string `json:"kelas"`
	AsalSekolah string `json:"asal_sekolah"`
	WhatsApp    string `json:"whatsapp"`
	Alamat      string `json:"alamat"`
	SiswaID     int    `json:"siswa_id,omitempty"`
	FCMToken 	string `json:"fcm_token"`
}
