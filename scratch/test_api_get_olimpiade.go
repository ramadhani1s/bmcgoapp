package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var SECRET_KEY = []byte("secret_bmc")

func GenerateToken(userID int, roleID int) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID,
		"role_id": roleID,
		"exp":     time.Now().Add(time.Hour * 24).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(SECRET_KEY)
}

func main() {
	token, err := GenerateToken(6, 3) // Yohana Nababan: user_id=6, role_id=3
	if err != nil {
		log.Fatalf("Gagal generate token: %v", err)
	}
	fmt.Printf("Generated Token: %s\n\n", token)

	client := &http.Client{}

	// Request 1: Get Olimpiade Tersedia
	req, err := http.NewRequest("GET", "http://localhost:8080/api/siswa/olimpiade?status=tersedia", nil)
	if err != nil {
		log.Fatalf("Gagal buat request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := client.Do(req)
	if err != nil {
		log.Fatalf("Gagal kirim request: %v", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	fmt.Printf("Response Tersedia (Status %d):\n%s\n\n", resp.StatusCode, string(body))

	// Request 2: Get Siswa Progress
	req2, err := http.NewRequest("GET", "http://localhost:8080/api/siswa/progress", nil)
	if err != nil {
		log.Fatalf("Gagal buat request progress: %v", err)
	}
	req2.Header.Set("Authorization", "Bearer "+token)

	resp2, err := client.Do(req2)
	if err != nil {
		log.Fatalf("Gagal kirim request progress: %v", err)
	}
	defer resp2.Body.Close()

	body2, _ := io.ReadAll(resp2.Body)
	fmt.Printf("Response Progress (Status %d):\n%s\n\n", resp2.StatusCode, string(body2))
}
