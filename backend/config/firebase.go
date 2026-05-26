package config

import (
	"context"
	"log"

	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"google.golang.org/api/option"
)

var FirebaseMessaging *messaging.Client

func InitFirebase() {

	opt := option.WithCredentialsFile("firebase-service-account.json")

	conf := &firebase.Config{
		ProjectID: "bintang-muda-center-pa02k01",
	}

	app, err := firebase.NewApp(context.Background(), conf, opt)
	if err != nil {
		log.Fatalf("error initializing firebase app: %v", err)
	}

	client, err := app.Messaging(context.Background())
	if err != nil {
		log.Fatalf("error getting messaging client: %v", err)
	}

	FirebaseMessaging = client

	log.Println("✅ Firebase initialized")
}
