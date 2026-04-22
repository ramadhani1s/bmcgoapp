package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// ================= ROLE CHECK =================
func RoleMiddleware(allowedRoles ...int) gin.HandlerFunc {
	return func(c *gin.Context) {

		roleIDInterface, exists := c.Get("role_id")
		if !exists {
			c.JSON(http.StatusForbidden, gin.H{
				"error": "Role tidak ditemukan",
			})
			c.Abort()
			return
		}

		roleID := roleIDInterface.(int)

		for _, allowed := range allowedRoles {
			if roleID == allowed {
				c.Next()
				return
			}
		}

		c.JSON(http.StatusForbidden, gin.H{
			"error": "Akses ditolak",
		})
		c.Abort()
	}
}
