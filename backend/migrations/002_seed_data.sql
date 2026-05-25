-- +goose Up
-- Insert default admin user (password: admin123)
INSERT INTO users (login, password, is_admin, card_id) VALUES ('admin', 'password', 1, NULL);
INSERT INTO users (login, password, is_admin, card_id) VALUES ('user', 'password123', 0, 1);

-- Insert sample keys
INSERT INTO keys (data) VALUES ('key_a1b2c3d4e5f6');
INSERT INTO keys (data) VALUES ('key_f6e5d4c3b2a1');

-- Insert sample cards
INSERT INTO cards (number, balance, blocked, owner_name, key_id) VALUES ('1234567890', 10000, 0, 'Belova Elizaveta', 1);
INSERT INTO cards (number, balance, blocked, owner_name, key_id) VALUES ('0987654321', 10, 0, 'Ivanov Matvey', 1);
INSERT INTO cards (number, balance, blocked, owner_name, key_id) VALUES ('1231231234', 1000, 0, 'Kamyshova Anastasya', 2);
INSERT INTO cards (number, balance, blocked, owner_name, key_id) VALUES ('1111222233', 0, 1, 'Blocked User', 2);

-- Insert sample terminals
INSERT INTO terminals (serial, address, name) VALUES ('TERM-001', 'Metro Station 1', 'Metro Terminal 1');
INSERT INTO terminals (serial, address, name) VALUES ('TERM-002', 'Metro Station 2', 'Metro Terminal 2');
INSERT INTO terminals (serial, address, name) VALUES ('BUS-001', 'Bus Stop Central', 'Bus Terminal');

-- +goose Down
DELETE FROM transactions;
DELETE FROM cards;
DELETE FROM terminals;
DELETE FROM keys;
DELETE FROM users;
