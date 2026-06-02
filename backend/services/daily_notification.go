package services

import (
	"context"
	"log"
	"time"

	"bmcgoapp-backend/config"
)

func StartDailyNotification() {
	go func() {

		lastSentDate := ""

		for {
			now := time.Now()

			currentDate := now.Format("2006-01-02")
			//currentHour := now.Hour()
			currentMinute := now.Minute()

			if true && currentMinute == 0 && lastSentDate != currentDate {

				log.Println("🔥 Kirim notifikasi latihan harian")

				tokens := getAllTokens()

				for _, token := range tokens {
					SendFCMNotification(
						token,
						"Latihan Soal Harian 📚",
						"Yuk kerjakan latihan soal hari ini!",
					)
				}

				lastSentDate = currentDate
			}

			time.Sleep(30 * time.Second)
		}
	}()
}

func getAllTokens() []string {
	rows, err := config.DB.Query(context.Background(),
		"SELECT fcm_token FROM users WHERE fcm_token IS NOT NULL",
	)
	if err != nil {
		log.Println("error query token:", err)
		return nil
	}
	defer rows.Close()

	var tokens []string

	for rows.Next() {
		var t string
		rows.Scan(&t)
		tokens = append(tokens, t)
	}

	return tokens
}
