-- +goose Up
CREATE TABLE users (
                       id INTEGER PRIMARY KEY,
                       login TEXT,
                       password TEXT,
                       is_admin BOOLEAN,
                       card_id INTEGER NULL,
                       FOREIGN KEY(card_id) REFERENCES cards(id)
);

CREATE TABLE keys (
                      id INTEGER PRIMARY KEY,
                      data TEXT
);

CREATE TABLE cards (
                       id INTEGER PRIMARY KEY,
                       number TEXT,
                       balance INTEGER,
                       blocked BOOLEAN,
                       owner_name TEXT,
                       key_id INTEGER,
                       FOREIGN KEY(key_id) REFERENCES keys(id)
);

CREATE TABLE terminals (
                           id INTEGER PRIMARY KEY,
                           serial TEXT,
                           address TEXT,
                           name TEXT
);

CREATE TABLE transactions (
                              id INTEGER PRIMARY KEY,
                              amount INTEGER,
                              card_id INTEGER,
                              terminal_id INTEGER,
                              created_at DATETIME
);

-- +goose Down
DROP TABLE transactions;
DROP TABLE cards;
DROP TABLE terminals;
DROP TABLE keys;
DROP TABLE users;