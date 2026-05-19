package main

import (
    "bmcgoapp-backend/config"
    "bmcgoapp-backend/repositories"
    "context"
    "fmt"
    "log"
)

func main() {
    config.ConnectDatabase()
    _, err := repositories.GetPendingPaymentVerifications(context.Background())
    if err != nil {
        log.Fatalf("Error: %v", err)
    }
    fmt.Println("Success")
}
