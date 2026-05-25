// handlers/handlers.go
package handlers

import (
	"net/http"
	"strconv"
	"time"

	"lab2/internal/models"
	"lab2/internal/service"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	svc *service.Service
}

func NewHandler(s *service.Service) *Handler {
	return &Handler{svc: s}
}

func (h *Handler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	user, err := h.svc.Authenticate(req.Login, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Error:   "AUTHENTICATION_FAILED",
			Message: err.Error(),
			Status:  http.StatusUnauthorized,
		})
		return
	}

	token, err := GenerateToken(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "TOKEN_GENERATION_FAILED",
			Message: "Failed to generate authentication token",
			Status:  http.StatusInternalServerError,
		})
		return
	}

	c.JSON(http.StatusOK, models.LoginResponse{
		Token: token,
		User:  user,
	})
}

func (h *Handler) GetCurrentUser(c *gin.Context) {
	userID := c.GetInt64("user_id")
	user, err := h.svc.GetUserByID(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "USER_NOT_FOUND",
			Message: "User not found",
			Status:  http.StatusNotFound,
		})
		return
	}
	c.JSON(http.StatusOK, user)
}

func (h *Handler) ListUsers(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can list users",
			Status:  http.StatusForbidden,
		})
		return
	}

	users, err := h.svc.GetAllUsers()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "DATABASE_ERROR",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, users)
}

func (h *Handler) GetUser(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can view user details",
			Status:  http.StatusForbidden,
		})
		return
	}

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid user ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	user, err := h.svc.GetUserByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "USER_NOT_FOUND",
			Message: "User not found",
			Status:  http.StatusNotFound,
		})
		return
	}
	c.JSON(http.StatusOK, user)
}

func (h *Handler) CreateUser(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can create users",
			Status:  http.StatusForbidden,
		})
		return
	}

	var req models.CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	user := &models.User{
		Login:    req.Login,
		Password: req.Password,
		IsAdmin:  req.IsAdmin,
		CardID:   req.CardID,
	}

	if req.CardID != nil {
		_, err := h.svc.GetCardByID(*req.CardID)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "INVALID_CARD_ID",
				Message: "Card with specified ID does not exist",
				Status:  http.StatusBadRequest,
			})
			return
		}
	}

	if err := h.svc.CreateUser(user); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "CREATION_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusCreated, user)
}

func (h *Handler) UpdateUser(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can update users",
			Status:  http.StatusForbidden,
		})
		return
	}

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid user ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	var req models.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	_, err = h.svc.GetUserByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	if req.CardID != nil {
		_, err := h.svc.GetCardByID(*req.CardID)
		if err != nil {
			c.JSON(http.StatusBadRequest, models.ErrorResponse{
				Error:   "INVALID_CARD_ID",
				Message: "Card with specified ID does not exist",
				Status:  http.StatusBadRequest,
			})
			return
		}
	}

	user := &models.User{
		ID:       id,
		Login:    req.Login,
		Password: req.Password,
		IsAdmin:  req.IsAdmin,
		CardID:   req.CardID,
	}

	if err := h.svc.UpdateUser(user, isAdmin); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "UPDATE_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, user)
}

func (h *Handler) DeleteUser(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can delete users",
			Status:  http.StatusForbidden,
		})
		return
	}

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid user ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	_, err = h.svc.GetUserByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	if err := h.svc.DeleteUser(id, isAdmin); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

func (h *Handler) ListCards(c *gin.Context) {
	cards, err := h.svc.GetAllCards()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "DATABASE_ERROR",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, cards)
}

func (h *Handler) GetCard(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid card ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	card, err := h.svc.GetCardByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "CARD_NOT_FOUND",
			Message: "Card not found",
			Status:  http.StatusNotFound,
		})
		return
	}
	c.JSON(http.StatusOK, card)
}

func (h *Handler) GetMyCard(c *gin.Context) {
	userID := c.GetInt64("user_id")
	isAdmin := c.GetBool("is_admin")

	if isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Use /cards endpoint for admin access",
			Status:  http.StatusForbidden,
		})
		return
	}

	card, err := h.svc.GetMyCard(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "CARD_NOT_FOUND",
			Message: err.Error(),
			Status:  http.StatusNotFound,
		})
		return
	}
	c.JSON(http.StatusOK, card)
}

func (h *Handler) CreateCard(c *gin.Context) {
	var req models.CreateCardRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	card := &models.Card{
		Number:    req.Number,
		Balance:   req.Balance,
		Blocked:   req.Blocked,
		OwnerName: req.OwnerName,
		KeyID:     req.KeyID,
	}

	if err := h.svc.CreateCard(card); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "CREATION_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusCreated, card)
}

func (h *Handler) UpdateCard(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid card ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	var req models.UpdateCardRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	_, err = h.svc.GetCardByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "CARD_NOT_FOUND",
			Message: "Card not found",
			Status:  http.StatusNotFound,
		})
		return
	}

	card := &models.Card{
		ID:        id,
		Number:    req.Number,
		Balance:   req.Balance,
		Blocked:   req.Blocked,
		OwnerName: req.OwnerName,
		KeyID:     req.KeyID,
	}

	if err := h.svc.UpdateCard(card); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "UPDATE_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, card)
}

func (h *Handler) DeleteCard(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid card ID format"})
		return
	}

	_, err = h.svc.GetCardByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "card not found"})
		return
	}

	if err := h.svc.DeleteCard(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

func (h *Handler) AuthorizeTransaction(c *gin.Context) {
	var req models.AuthRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	err := h.svc.AuthorizeTransaction(req.CardNumber, req.Amount, req.TerminalID)
	if err != nil {
		c.JSON(http.StatusForbidden, models.AuthResponse{
			Status: "declined",
			Reason: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.AuthResponse{
		Status: "approved",
	})
}

func (h *Handler) GetKeysForTerminal(c *gin.Context) {
	keys, err := h.svc.GetKeysForTerminal()
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "DATABASE_ERROR",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, keys)
}

func (h *Handler) ListTransactions(c *gin.Context) {
	txs, err := h.svc.GetAllTransactions()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, txs)
}

func (h *Handler) GetMyTransactions(c *gin.Context) {
	userID := c.GetInt64("user_id")
	isAdmin := c.GetBool("is_admin")

	if isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Use /transactions endpoint for admin access",
			Status:  http.StatusForbidden,
		})
		return
	}

	txs, err := h.svc.GetMyTransactions(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "TRANSACTIONS_NOT_FOUND",
			Message: err.Error(),
			Status:  http.StatusNotFound,
		})
		return
	}
	c.JSON(http.StatusOK, txs)
}

func (h *Handler) CreateTransaction(c *gin.Context) {
	var req models.CreateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	tx := &models.Transaction{
		Amount:     req.Amount,
		CardID:     req.CardID,
		TerminalID: req.TerminalID,
	}
	if req.CreatedAt != nil && !req.CreatedAt.IsZero() {
		tx.CreatedAt = req.CreatedAt.Time
	} else {
		tx.CreatedAt = time.Now()
	}

	if err := h.svc.CreateTransaction(tx); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "CREATION_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusCreated, tx)
}

func (h *Handler) GetTransaction(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid transaction ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	tx, err := h.svc.GetTransactionByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "TRANSACTION_NOT_FOUND",
			Message: "Transaction not found",
			Status:  http.StatusNotFound,
		})
		return
	}
	c.JSON(http.StatusOK, tx)
}

func (h *Handler) UpdateTransaction(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can update transactions",
			Status:  http.StatusForbidden,
		})
		return
	}

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid transaction ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	var req models.UpdateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_REQUEST",
			Message: err.Error(),
			Status:  http.StatusBadRequest,
		})
		return
	}

	_, err = h.svc.GetTransactionByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "TRANSACTION_NOT_FOUND",
			Message: "Transaction not found",
			Status:  http.StatusNotFound,
		})
		return
	}

	tx := &models.Transaction{
		ID:         id,
		Amount:     req.Amount,
		CardID:     req.CardID,
		TerminalID: req.TerminalID,
		CreatedAt:  req.CreatedAt.Time,
	}

	if err := h.svc.UpdateTransaction(tx); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "UPDATE_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.JSON(http.StatusOK, tx)
}

func (h *Handler) DeleteTransaction(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, models.ErrorResponse{
			Error:   "ACCESS_DENIED",
			Message: "Only administrators can delete transactions",
			Status:  http.StatusForbidden,
		})
		return
	}

	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "INVALID_ID",
			Message: "Invalid transaction ID format",
			Status:  http.StatusBadRequest,
		})
		return
	}

	_, err = h.svc.GetTransactionByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Error:   "TRANSACTION_NOT_FOUND",
			Message: "Transaction not found",
			Status:  http.StatusNotFound,
		})
		return
	}

	if err := h.svc.DeleteTransaction(id); err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "DELETE_FAILED",
			Message: err.Error(),
			Status:  http.StatusInternalServerError,
		})
		return
	}
	c.Status(http.StatusNoContent)
}

func (h *Handler) ListTerminals(c *gin.Context) {
	terminals, err := h.svc.GetAllTerminals()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, terminals)
}

func (h *Handler) GetTerminal(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	terminal, err := h.svc.GetTerminalByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "terminal not found"})
		return
	}
	c.JSON(http.StatusOK, terminal)
}

func (h *Handler) CreateTerminal(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, gin.H{"error": "only admin can create terminals"})
		return
	}
	var t models.Terminal
	if err := c.ShouldBindJSON(&t); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.svc.CreateTerminal(&t); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, t)
}

func (h *Handler) UpdateTerminal(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, gin.H{"error": "only admin can update terminals"})
		return
	}
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	var t models.Terminal
	if err := c.ShouldBindJSON(&t); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	t.ID = id
	_, err := h.svc.GetTerminalByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "terminal not found"})
		return
	}
	if err := h.svc.UpdateTerminal(&t); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, t)
}

func (h *Handler) DeleteTerminal(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	if !isAdmin {
		c.JSON(http.StatusForbidden, gin.H{"error": "only admin can delete terminals"})
		return
	}
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	_, err := h.svc.GetTerminalByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "terminal not found"})
		return
	}
	if err := h.svc.DeleteTerminal(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

func (h *Handler) ListKeys(c *gin.Context) {
	keys, err := h.svc.GetAllKeys()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, keys)
}

func (h *Handler) GetKey(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	key, err := h.svc.GetKeyByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "key not found"})
		return
	}
	c.JSON(http.StatusOK, key)
}

func (h *Handler) CreateKey(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	var key models.Key
	if err := c.ShouldBindJSON(&key); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.svc.CreateKey(&key, isAdmin); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, key)
}

func (h *Handler) UpdateKey(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	var key models.Key
	if err := c.ShouldBindJSON(&key); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	key.ID = id
	_, err := h.svc.GetKeyByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "key not found"})
		return
	}
	if err := h.svc.UpdateKey(&key, isAdmin); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, key)
}

func (h *Handler) DeleteKey(c *gin.Context) {
	isAdmin := c.GetBool("is_admin")
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	if err := h.svc.DeleteKey(id, isAdmin); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}
