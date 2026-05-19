package main

import (
    "bmcgoapp-backend/config"
    "bmcgoapp-backend/repositories"
    "context"
    "fmt"
    "log"
)

func main() {
    config.ConnectDB()
    items, err := repositories.GetPendingPaymentVerifications(context.Background())
    if err != nil {
        log.Fatalf("Error repo: %v", err)
    }
    fmt.Printf("Repo Success, got %d items\n", len(items))
}
