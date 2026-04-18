package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

var SECRET_KEY = []byte("secret_bmc")

// ================= AUTH MIDDLEWARE =================
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {

		authHeader := c.GetHeader("Authorization")

		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Token tidak ditemukan",
			})
			c.Abort()
			return
		}

		// format: Bearer TOKEN
		tokenString := strings.Split(authHeader, " ")
		if len(tokenString) != 2 {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Format token salah",
			})
			c.Abort()
			return
		}

		token, err := jwt.Parse(tokenString[1], func(token *jwt.Token) (interface{}, error) {
			return SECRET_KEY, nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Token tidak valid",
			})
			c.Abort()
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Token claims error",
			})
			c.Abort()
			return
		}

		// simpan ke context
		c.Set("user_id", int(claims["user_id"].(float64)))
		c.Set("role_id", int(claims["role_id"].(float64)))

		c.Next()
	}
}
