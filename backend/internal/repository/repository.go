package repository

import (
	"database/sql"
	"lab2/internal/models"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) GetUserByLogin(login string) (*models.User, error) {
	row := r.db.QueryRow("SELECT id, login, password, is_admin, card_id FROM users WHERE login = ?", login)
	var u models.User
	var isAdmin int
	var cardID sql.NullInt64
	err := row.Scan(&u.ID, &u.Login, &u.Password, &isAdmin, &cardID)
	if err != nil {
		return nil, err
	}
	u.IsAdmin = isAdmin != 0
	if cardID.Valid {
		u.CardID = &cardID.Int64
	}
	return &u, nil
}

func (r *Repository) GetUserByID(id int64) (*models.User, error) {
	row := r.db.QueryRow("SELECT id, login, password, is_admin, card_id FROM users WHERE id = ?", id)
	var u models.User
	var isAdmin int
	var cardID sql.NullInt64
	err := row.Scan(&u.ID, &u.Login, &u.Password, &isAdmin, &cardID)
	if err != nil {
		return nil, err
	}
	u.IsAdmin = isAdmin != 0
	if cardID.Valid {
		u.CardID = &cardID.Int64
	}
	return &u, nil
}

func (r *Repository) CreateUser(u *models.User) error {
	var cardID interface{}
	if u.CardID != nil {
		cardID = *u.CardID
	} else {
		cardID = nil
	}

	result, err := r.db.Exec("INSERT INTO users (login, password, is_admin, card_id) VALUES (?, ?, ?, ?)",
		u.Login, u.Password, u.IsAdmin, cardID)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	u.ID = id
	return nil
}

func (r *Repository) UpdateUser(u *models.User) error {
	var cardID interface{}
	if u.CardID != nil {
		cardID = *u.CardID
	} else {
		cardID = nil
	}

	_, err := r.db.Exec("UPDATE users SET login = ?, password = ?, is_admin = ?, card_id = ? WHERE id = ?",
		u.Login, u.Password, u.IsAdmin, cardID, u.ID)
	return err
}

func (r *Repository) DeleteUser(id int64) error {
	_, err := r.db.Exec("DELETE FROM users WHERE id = ?", id)
	return err
}

func (r *Repository) GetAllUsers() ([]models.User, error) {
	rows, err := r.db.Query("SELECT id, login, password, is_admin, card_id FROM users")
	if err != nil {
		return []models.User{}, nil
	}
	defer rows.Close()

	users := make([]models.User, 0)
	for rows.Next() {
		var u models.User
		var isAdmin int
		var cardID sql.NullInt64
		if err := rows.Scan(&u.ID, &u.Login, &u.Password, &isAdmin, &cardID); err != nil {
			return []models.User{}, nil
		}
		u.IsAdmin = isAdmin != 0
		if cardID.Valid {
			u.CardID = &cardID.Int64
		}
		users = append(users, u)
	}
	return users, nil
}

func (r *Repository) GetCardByUserID(userID int64) (*models.Card, error) {
	var cardID int64
	err := r.db.QueryRow("SELECT card_id FROM users WHERE id = ? AND card_id IS NOT NULL", userID).Scan(&cardID)
	if err != nil {
		return nil, err
	}
	return r.GetCardByID(cardID)
}

func (r *Repository) GetTransactionsByCardID(cardID int64) ([]models.Transaction, error) {
	rows, err := r.db.Query("SELECT id, amount, card_id, terminal_id, created_at FROM transactions WHERE card_id = ? ORDER BY created_at DESC", cardID)
	if err != nil {
		return []models.Transaction{}, nil
	}
	defer rows.Close()

	txs := make([]models.Transaction, 0)
	for rows.Next() {
		var t models.Transaction
		if err := rows.Scan(&t.ID, &t.Amount, &t.CardID, &t.TerminalID, &t.CreatedAt); err != nil {
			return []models.Transaction{}, nil
		}
		txs = append(txs, t)
	}
	return txs, nil
}
func (r *Repository) GetCardByID(id int64) (*models.Card, error) {
	row := r.db.QueryRow("SELECT id, number, balance, blocked, owner_name, key_id FROM cards WHERE id = ?", id)
	var c models.Card
	var blocked int
	err := row.Scan(&c.ID, &c.Number, &c.Balance, &blocked, &c.OwnerName, &c.KeyID)
	if err != nil {
		return nil, err
	}
	c.Blocked = blocked != 0
	return &c, nil
}

func (r *Repository) GetCardByNumber(number string) (*models.Card, error) {
	row := r.db.QueryRow("SELECT id, number, balance, blocked, owner_name, key_id FROM cards WHERE number = ?", number)
	var c models.Card
	var blocked int
	err := row.Scan(&c.ID, &c.Number, &c.Balance, &blocked, &c.OwnerName, &c.KeyID)
	if err != nil {
		return nil, err
	}
	c.Blocked = blocked != 0
	return &c, nil
}

func (r *Repository) GetAllCards() ([]models.Card, error) {
	rows, err := r.db.Query("SELECT id, number, balance, blocked, owner_name, key_id FROM cards")
	if err != nil {
		return []models.Card{}, nil
	}
	defer rows.Close()

	cards := make([]models.Card, 0)
	for rows.Next() {
		var c models.Card
		var blocked int
		if err := rows.Scan(&c.ID, &c.Number, &c.Balance, &blocked, &c.OwnerName, &c.KeyID); err != nil {
			return []models.Card{}, nil
		}
		c.Blocked = blocked != 0
		cards = append(cards, c)
	}
	return cards, nil
}

func (r *Repository) CreateCard(c *models.Card) error {
	result, err := r.db.Exec("INSERT INTO cards (number, balance, blocked, owner_name, key_id) VALUES (?, ?, ?, ?, ?)",
		c.Number, c.Balance, c.Blocked, c.OwnerName, c.KeyID)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	c.ID = id
	return nil
}

func (r *Repository) UpdateCard(c *models.Card) error {
	_, err := r.db.Exec("UPDATE cards SET number = ?, balance = ?, blocked = ?, owner_name = ?, key_id = ? WHERE id = ?",
		c.Number, c.Balance, c.Blocked, c.OwnerName, c.KeyID, c.ID)
	return err
}

func (r *Repository) DeleteCard(id int64) error {
	_, err := r.db.Exec("DELETE FROM cards WHERE id = ?", id)
	return err
}

func (r *Repository) UpdateBalance(cardID int64, newBalance int64) error {
	_, err := r.db.Exec("UPDATE cards SET balance = ? WHERE id = ?", newBalance, cardID)
	return err
}

func (r *Repository) GetTerminalByID(id int64) (*models.Terminal, error) {
	row := r.db.QueryRow("SELECT id, serial, address, name FROM terminals WHERE id = ?", id)
	var t models.Terminal
	err := row.Scan(&t.ID, &t.Serial, &t.Address, &t.Name)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *Repository) GetAllTerminals() ([]models.Terminal, error) {
	rows, err := r.db.Query("SELECT id, serial, address, name FROM terminals")
	if err != nil {
		return []models.Terminal{}, nil
	}
	defer rows.Close()

	terminals := make([]models.Terminal, 0)
	for rows.Next() {
		var t models.Terminal
		if err := rows.Scan(&t.ID, &t.Serial, &t.Address, &t.Name); err != nil {
			return []models.Terminal{}, nil
		}
		terminals = append(terminals, t)
	}
	return terminals, nil
}

func (r *Repository) CreateTerminal(t *models.Terminal) error {
	result, err := r.db.Exec("INSERT INTO terminals (serial, address, name) VALUES (?, ?, ?)",
		t.Serial, t.Address, t.Name)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	t.ID = id
	return nil
}

func (r *Repository) UpdateTerminal(t *models.Terminal) error {
	_, err := r.db.Exec("UPDATE terminals SET serial = ?, address = ?, name = ? WHERE id = ?",
		t.Serial, t.Address, t.Name, t.ID)
	return err
}

func (r *Repository) DeleteTerminal(id int64) error {
	_, err := r.db.Exec("DELETE FROM terminals WHERE id = ?", id)
	return err
}

func (r *Repository) GetAllTransactions() ([]models.Transaction, error) {
	rows, err := r.db.Query("SELECT id, amount, card_id, terminal_id, created_at FROM transactions ORDER BY created_at DESC")
	if err != nil {
		return []models.Transaction{}, nil
	}
	defer rows.Close()

	txs := make([]models.Transaction, 0)
	for rows.Next() {
		var t models.Transaction
		if err := rows.Scan(&t.ID, &t.Amount, &t.CardID, &t.TerminalID, &t.CreatedAt); err != nil {
			return []models.Transaction{}, nil
		}
		txs = append(txs, t)
	}
	return txs, nil
}

func (r *Repository) CreateTransaction(tx *models.Transaction) error {
	result, err := r.db.Exec("INSERT INTO transactions (amount, card_id, terminal_id, created_at) VALUES (?, ?, ?, ?)",
		tx.Amount, tx.CardID, tx.TerminalID, tx.CreatedAt)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	tx.ID = id
	return nil
}

func (r *Repository) GetTransactionByID(id int64) (*models.Transaction, error) {
	row := r.db.QueryRow("SELECT id, amount, card_id, terminal_id, created_at FROM transactions WHERE id = ?", id)
	var tx models.Transaction
	err := row.Scan(&tx.ID, &tx.Amount, &tx.CardID, &tx.TerminalID, &tx.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &tx, nil
}

func (r *Repository) UpdateTransaction(tx *models.Transaction) error {
	_, err := r.db.Exec("UPDATE transactions SET amount = ?, card_id = ?, terminal_id = ?, created_at = ? WHERE id = ?",
		tx.Amount, tx.CardID, tx.TerminalID, tx.CreatedAt, tx.ID)
	return err
}

func (r *Repository) DeleteTransaction(id int64) error {
	_, err := r.db.Exec("DELETE FROM transactions WHERE id = ?", id)
	return err
}

func (r *Repository) GetKeyByID(id int64) (*models.Key, error) {
	row := r.db.QueryRow("SELECT id, data FROM keys WHERE id = ?", id)
	var k models.Key
	err := row.Scan(&k.ID, &k.Data)
	if err != nil {
		return nil, err
	}
	return &k, nil
}

func (r *Repository) GetAllKeys() ([]models.Key, error) {
	rows, err := r.db.Query("SELECT id, data FROM keys")
	if err != nil {
		return []models.Key{}, nil
	}
	defer rows.Close()

	keys := make([]models.Key, 0)
	for rows.Next() {
		var k models.Key
		if err := rows.Scan(&k.ID, &k.Data); err != nil {
			return []models.Key{}, nil
		}
		keys = append(keys, k)
	}
	return keys, nil
}

func (r *Repository) CreateKey(k *models.Key) error {
	result, err := r.db.Exec("INSERT INTO keys (data) VALUES (?)", k.Data)
	if err != nil {
		return err
	}
	id, _ := result.LastInsertId()
	k.ID = id
	return nil
}

func (r *Repository) UpdateKey(k *models.Key) error {
	_, err := r.db.Exec("UPDATE keys SET data = ? WHERE id = ?", k.Data, k.ID)
	return err
}

func (r *Repository) DeleteKey(id int64) error {
	_, err := r.db.Exec("DELETE FROM keys WHERE id = ?", id)
	return err
}
