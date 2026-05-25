package handlers

import (
	"time"

	"lab2/internal/models"

	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret = []byte("transport-cards-secret-key-2024")

type Claims struct {
	UserID int64  `json:"user_id"`
	Login  string `json:"login"`
	IsAdmin bool  `json:"is_admin"`
	jwt.RegisteredClaims
}

func GenerateToken(user *models.User) (string, error) {
	claims := &Claims{
		UserID:  user.ID,
		Login:   user.Login,
		IsAdmin: user.IsAdmin,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

func ParseToken(tokenStr string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})
	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}
	return nil, jwt.ErrSignatureInvalid
}
