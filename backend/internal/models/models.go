// models/models.go
package models

import (
	"encoding/json"
	"reflect"
	"time"
)

type User struct {
	ID       int64  `json:"id" example:"1" description:"Unique user identifier"`
	Login    string `json:"login" example:"admin" description:"User login name"`
	Password string `json:"-" example:"-" description:"User password (never returned)"`
	IsAdmin  bool   `json:"is_admin" example:"true" description:"Administrator privileges flag"`
	CardID   *int64 `json:"card_id,omitempty" example:"1" description:"Associated card ID (null for admin)"`
}

type CreateUserRequest struct {
	Login    string `json:"login" binding:"required,min=3,max=50" example:"newuser" description:"User login (3-50 characters)"`
	Password string `json:"password" binding:"required,min=6,max=100" example:"password123" description:"User password (6-100 characters)"`
	IsAdmin  bool   `json:"is_admin" example:"false" description:"Administrator privileges"`
	CardID   *int64 `json:"card_id" example:"1" description:"Card ID to assign to user (optional)"`
}

type UpdateUserRequest struct {
	Login    string `json:"login" binding:"required,min=3,max=50" example:"updateduser" description:"User login (3-50 characters)"`
	Password string `json:"password" binding:"omitempty,min=6,max=100" example:"newpassword123" description:"User password (6-100 characters)"`
	IsAdmin  bool   `json:"is_admin" example:"true" description:"Administrator privileges"`
	CardID   *int64 `json:"card_id" example:"1" description:"Card ID to assign to user"`
}

type Card struct {
	ID        int64  `json:"id" example:"1" description:"Unique card identifier"`
	Number    string `json:"number" example:"1234567890" description:"Card number (10 digits)"`
	Balance   int64  `json:"balance" example:"1000" description:"Current balance in cents"`
	Blocked   bool   `json:"blocked" example:"false" description:"Card blocked status"`
	OwnerName string `json:"owner_name" example:"Ivan Ivanov" description:"Card owner full name"`
	KeyID     int64  `json:"key_id" example:"1" description:"Associated cryptographic key ID"`
}

type CreateCardRequest struct {
	Number    string `json:"number" binding:"required,len=10" example:"1234567890" description:"Card number (exactly 10 digits)"`
	Balance   int64  `json:"balance" binding:"required,min=0" example:"500" description:"Initial balance in cents"`
	Blocked   bool   `json:"blocked" example:"false" description:"Initial blocked status"`
	OwnerName string `json:"owner_name" binding:"required" example:"Ivan Ivanov" description:"Card owner full name"`
	KeyID     int64  `json:"key_id" binding:"required" example:"1" description:"Associated cryptographic key ID"`
}

type UpdateCardRequest struct {
	Number    string `json:"number" binding:"required,len=10" example:"1234567890" description:"Card number (exactly 10 digits)"`
	Balance   int64  `json:"balance" binding:"required,min=0" example:"750" description:"Updated balance in cents"`
	Blocked   bool   `json:"blocked" example:"true" description:"Updated blocked status"`
	OwnerName string `json:"owner_name" binding:"required" example:"Petr Petrov" description:"Updated owner full name"`
	KeyID     int64  `json:"key_id" binding:"required" example:"2" description:"Associated cryptographic key ID"`
}

type Terminal struct {
	ID      int64  `json:"id" example:"1" description:"Unique terminal identifier"`
	Serial  string `json:"serial" example:"TERM-001" description:"Terminal serial number"`
	Address string `json:"address" example:"Metro Station 1" description:"Terminal physical address"`
	Name    string `json:"name" example:"Metro Terminal 1" description:"Terminal display name"`
}

type Transaction struct {
	ID         int64     `json:"id" example:"1" description:"Unique transaction identifier"`
	Amount     int64     `json:"amount" example:"100" description:"Transaction amount in cents"`
	CardID     int64     `json:"card_id" example:"1" description:"Associated card ID"`
	TerminalID int64     `json:"terminal_id" example:"1" description:"Associated terminal ID"`
	CreatedAt  time.Time `json:"created_at" example:"2024-01-15T10:30:00Z" description:"Transaction timestamp"`
}

type CustomTime struct {
	time.Time
}

func (ct CustomTime) MarshalJSON() ([]byte, error) {
	return []byte(`"` + ct.Time.Format("02.01.2006 15:04") + `"`), nil
}

// парсинг из JSON (поддерживаем оба формата)
func (ct *CustomTime) UnmarshalJSON(b []byte) error {
	s := string(b)
	if len(s) >= 2 {
		s = s[1 : len(s)-1]
	}

	// парсит в формате dd.mm.yyyy hh:mm
	if t, err := time.Parse("02.01.2006 15:04", s); err == nil {
		ct.Time = t
		return nil
	}

	//стандартный RFC3339
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		ct.Time = t
		return nil
	}

	return &json.UnmarshalTypeError{Value: s, Type: reflect.TypeOf(ct)}
}

type CreateTransactionRequest struct {
	Amount     int64       `json:"amount" binding:"required,min=1" example:"150" description:"Transaction amount in cents"`
	CardID     int64       `json:"card_id" binding:"required" example:"1" description:"Associated card ID"`
	TerminalID int64       `json:"terminal_id" binding:"required" example:"1" description:"Associated terminal ID"`
	CreatedAt  *CustomTime `json:"created_at" example:"17.04.2026 10:30"`
}

type UpdateTransactionRequest struct {
	Amount     int64      `json:"amount" binding:"required,min=1" example:"150"`
	CardID     int64      `json:"card_id" binding:"required" example:"1"`
	TerminalID int64      `json:"terminal_id" binding:"required" example:"1"`
	CreatedAt  CustomTime `json:"created_at" binding:"required" example:"17.04.2026 10:30"`
}

type Key struct {
	ID   int64  `json:"id" example:"1" description:"Unique key identifier"`
	Data string `json:"data" example:"key_a1b2c3d4e5f6" description:"Key data (hex string)"`
}

type LoginRequest struct {
	Login    string `json:"login" binding:"required" example:"admin" description:"User login"`
	Password string `json:"password" binding:"required" example:"admin123" description:"User password"`
}

type LoginResponse struct {
	Token string `json:"token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." description:"JWT access token"`
	User  *User  `json:"user" description:"Authenticated user information"`
}

type AuthRequest struct {
	CardNumber string `json:"card_number" binding:"required,len=10" example:"1234567890" description:"Card number (10 digits)"`
	Amount     int64  `json:"amount" binding:"required,min=1" example:"100" description:"Payment amount in cents"`
	TerminalID int64  `json:"terminal_id" binding:"required" example:"1" description:"Terminal ID"`
}

type AuthResponse struct {
	Status string `json:"status" example:"approved" description:"Payment status (approved/declined)"`
	Reason string `json:"reason,omitempty" example:"Insufficient funds" description:"Decline reason (if declined)"`
}

type ErrorResponse struct {
	Error   string `json:"error" example:"INVALID_REQUEST" description:"Error code"`
	Message string `json:"message" example:"Invalid request parameters" description:"Human-readable error message"`
	Status  int    `json:"status" example:"400" description:"HTTP status code"`
}
