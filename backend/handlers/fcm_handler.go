package handlers

import (
	"context"
	"net/http"

	"bmcgoapp-backend/config"

	"bmcgoapp-backend/services"

	"github.com/gin-gonic/gin"
)

type SaveFCMTokenRequest struct {
	UserID   int    `json:"user_id"`
	FCMToken string `json:"fcm_token"`
}

func SaveFCMToken(c *gin.Context) {
	var req SaveFCMTokenRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	_, err := config.DB.Exec(
		context.Background(),
		"UPDATE users SET fcm_token=$1 WHERE id=$2",
		req.FCMToken,
		req.UserID,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "failed save token",
		})
		return
	}

	err = services.SendFCMNotification(
		req.FCMToken,
		"Selamat datang di Bimbel BMC 🔥",
		"Lengkapi profil kamu untuk memulai!",
	)

	c.JSON(http.StatusOK, gin.H{
		"message": "FCM token saved successfully",
	})
}
