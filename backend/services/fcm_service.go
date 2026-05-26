package services

import (
	"context"

	"bmcgoapp-backend/config"

	"firebase.google.com/go/messaging"
)

func SendFCMNotification(token string, title string, body string) error {

	message := &messaging.Message{
		Token: token,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
	}

	_, err := config.FirebaseMessaging.Send(context.Background(), message)

	return err
}