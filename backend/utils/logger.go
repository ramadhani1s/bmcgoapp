package utils

import (
	"fmt"
	"os"
	"time"
)

// LogApproval appends an approval-related message to a log file with timestamp.
func LogApproval(msg string) error {
	dir := "./logs"
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	fpath := dir + "/approval.log"
	f, err := os.OpenFile(fpath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()

	t := time.Now().Format(time.RFC3339)
	_, err = fmt.Fprintf(f, "%s - %s\n", t, msg)
	return err
}
