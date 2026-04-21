package models

import "time"

// PaymentTransaction struct untuk menyimpan history pembayaran
type PaymentTransaction struct {
	ID                   string `gorm:"primaryKey"`
	UserID               string `gorm:"index"`
	PackageID            string
	PackageTitle         string
	Amount               int64
	TransactionID        string `gorm:"uniqueIndex"`
	Status               string // pending, settlement, capture, deny, cancel
	PaymentType          string // bank_transfer, credit_card, dll
	PaymentChannel       string // bni_va, bca_va, dll
	VirtualAccountNumber string
	CustomerName         string
	CustomerEmail        string
	CustomerPhone        string
	Timestamp            time.Time
	UpdatedAt            time.Time
	SettlementTime       *time.Time // waktu settlement/pembayaran berhasil
	Notes                string
	CreatedAt            time.Time
}

// TableName menentukan nama table di database
func (PaymentTransaction) TableName() string {
	return "payment_transactions"
}

/**
 * MIGRATION SQL untuk membuat table:
 *
 * CREATE TABLE payment_transactions (
 *   id VARCHAR(255) PRIMARY KEY,
 *   user_id VARCHAR(255) NOT NULL,
 *   package_id VARCHAR(255),
 *   package_title VARCHAR(255),
 *   amount BIGINT,
 *   transaction_id VARCHAR(255) UNIQUE NOT NULL,
 *   status VARCHAR(50),
 *   payment_type VARCHAR(50),
 *   payment_channel VARCHAR(50),
 *   virtual_account_number VARCHAR(255),
 *   customer_name VARCHAR(255),
 *   customer_email VARCHAR(255),
 *   customer_phone VARCHAR(255),
 *   timestamp TIMESTAMP,
 *   updated_at TIMESTAMP,
 *   settlement_time TIMESTAMP NULL,
 *   notes TEXT,
 *   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *   INDEX idx_user_id (user_id),
 *   INDEX idx_transaction_id (transaction_id)
 * );
 */
