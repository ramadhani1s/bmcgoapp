package handlers

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"bmcgoapp-backend/config"

	"github.com/gin-gonic/gin"
)

// UploadFileHandler handles single file uploads and saves them to ./uploads
func UploadFileHandler(c *gin.Context) {
	// ensure uploads directory exists
	uploadDir := "./uploads"
	if _, err := os.Stat(uploadDir); os.IsNotExist(err) {
		if err := os.MkdirAll(uploadDir, 0755); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create upload dir"})
			return
		}
	}

	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file is required"})
		return
	}

	// only allow jpg/jpeg/png
	ext := filepath.Ext(file.Filename)
	switch ext {
	case ".jpg", ".jpeg", ".png":
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "only JPG/JPEG/PNG allowed"})
		return
	}

	// generate unique filename
	fname := fmt.Sprintf("%d_%s", time.Now().UnixNano(), file.Filename)
	dest := filepath.Join(uploadDir, fname)

	if err := c.SaveUploadedFile(file, dest); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save file"})
		return
	}

	// return accessible URL path
	url := "/uploads/" + fname

	// optional: record metadata in DB (not required now)
	_ = config.DB // keep import used

	c.JSON(http.StatusOK, gin.H{"url": url, "message": "file uploaded"})
}
