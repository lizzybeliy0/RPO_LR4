import React, { useState, useEffect } from 'react';
import { users, cards } from '../../services/api';
import { User, Card } from '../../types';

const Users: React.FC = () => {
    const [usersList, setUsersList] = useState<User[]>([]);
    const [cardsList, setCardsList] = useState<Card[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingUser, setEditingUser] = useState<User | null>(null);
    const [searchId, setSearchId] = useState('');

    useEffect(() => {
        fetchUsers();
        fetchCards();
    }, []);

    const fetchUsers = async () => {
        try {
            const response = await users.getAll();
            const data = response?.data;
            if (Array.isArray(data)) {
                setUsersList(data);
            } else {
                setUsersList([]);
            }
        } catch (err) {
            console.error('Error fetching users:', err);
            setUsersList([]);
        } finally {
            setLoading(false);
        }
    };

    const fetchCards = async () => {
        try {
            const response = await cards.getAll();
            const data = response?.data;
            if (Array.isArray(data)) {
                setCardsList(data);
            } else {
                setCardsList([]);
            }
        } catch (err) {
            console.error('Error fetching cards:', err);
            setCardsList([]);
        }
    };

    const handleDelete = async (id: number) => {
        try {
            await users.delete(id);
            await fetchUsers();
        } catch (err) {
            alert('Ошибка удаления');
        }
    };

    const handleSave = async (data: Partial<User>, id?: number) => {
        try {
            if (id) {
                await users.update(id, data);
            } else {
                await users.create(data);
            }
            await fetchUsers();
            setShowModal(false);
            setEditingUser(null);
        } catch (err) {
            alert('Ошибка сохранения');
        }
    };

    // Защита от null
    const safeList = Array.isArray(usersList) ? usersList : [];
    const filteredUsers = searchId
        ? safeList.filter(u => u.id === parseInt(searchId))
        : safeList;

    return (
        <div className="users-container">
            <div className="header-actions">
                <h2>Управление пользователями</h2>
                <div className="actions">
                    <input
                        type="text"
                        placeholder="Поиск по ID..."
                        value={searchId}
                        onChange={(e) => setSearchId(e.target.value)}
                        className="search-input"
                    />
                    <button onClick={() => {
                        setEditingUser(null);
                        setShowModal(true);
                    }}>+ Добавить пользователя</button>
                </div>
            </div>

            {loading ? (
                <div className="loading">Загрузка...</div>
            ) : filteredUsers.length === 0 ? (
                <div className="empty-state">
                    <p>Нет пользователей</p>
                    <p>Нажмите "+ Добавить пользователя" чтобы создать первого пользователя</p>
                </div>
            ) : (
                <table className="users-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Логин</th>
                            <th>Админ</th>
                            <th>Card ID</th>
                            <th>Действия</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredUsers.map(user => (
                            <tr key={user.id}>
                                <td>{user.id}</td>
                                <td>{user.login}</td>
                                <td>{user.is_admin ? 'Да' : 'Нет'}</td>
                                <td>{user.card_id || '—'}</td>
                                <td>
                                    <button onClick={() => {
                                        setEditingUser(user);
                                        setShowModal(true);
                                    }}>Изменить</button>
                                    <button className="danger" onClick={() => handleDelete(user.id)}>Удалить</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}

            {showModal && (
                <UserForm
                    user={editingUser}
                    cardsList={cardsList}
                    onClose={() => {
                        setShowModal(false);
                        setEditingUser(null);
                    }}
                    onSave={handleSave}
                />
            )}
        </div>
    );
};

// UserForm компонент
const UserForm: React.FC<{
    user: User | null;
    cardsList: Card[];
    onClose: () => void;
    onSave: (data: Partial<User>, id?: number) => void;
}> = ({ user, cardsList, onClose, onSave }) => {
    const [formData, setFormData] = useState({
        login: user?.login || '',
        password: '',
        is_admin: user?.is_admin || false,
        card_id: user?.card_id || null,
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSave(formData, user?.id);
    };

    return (
        <div className="modal" onClick={onClose}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                <h3>{user ? 'Редактировать пользователя' : 'Новый пользователь'}</h3>
                <form onSubmit={handleSubmit}>
                    <input
                        type="text"
                        placeholder="Логин"
                        value={formData.login}
                        onChange={(e) => setFormData({ ...formData, login: e.target.value })}
                        required
                    />
                    <input
                        type="password"
                        placeholder="Пароль"
                        value={formData.password}
                        onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                        required={!user}
                    />
                    <select
                        value={formData.card_id || ''}
                        onChange={(e) => setFormData({ ...formData, card_id: e.target.value ? parseInt(e.target.value) : null })}
                    >
                        <option value="">Без карты</option>
                        {cardsList.map(card => (
                            <option key={card.id} value={card.id}>
                                #{card.id} - {card.owner_name} ({card.number})
                            </option>
                        ))}
                    </select>
                    <label>
                        <input
                            type="checkbox"
                            checked={formData.is_admin}
                            onChange={(e) => setFormData({ ...formData, is_admin: e.target.checked })}
                        />
                        Администратор
                    </label>
                    <div className="modal-buttons">
                        <button type="button" onClick={onClose}>Отмена</button>
                        <button type="submit">Сохранить</button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default Users;