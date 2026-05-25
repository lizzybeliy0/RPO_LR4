import React, { useState, useEffect } from 'react';
import { cards, keys } from '../../services/api';
import { Card, Key } from '../../types';
import CardForm from './CardsForm';
import './Cards.css';

const Cards: React.FC = () => {
    const [cardsList, setCardsList] = useState<Card[]>([]);
    const [keysList, setKeysList] = useState<Key[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingCard, setEditingCard] = useState<Card | null>(null);
    const [searchId, setSearchId] = useState('');

    useEffect(() => {
        fetchCards();
        fetchKeys();
    }, []);

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
        } finally {
            setLoading(false);
        }
    };

    const fetchKeys = async () => {
        try {
            const response = await keys.getAll();
            const data = response?.data;
            if (Array.isArray(data)) {
                setKeysList(data);
            } else {
                setKeysList([]);
            }
        } catch (err) {
            console.error('Error fetching keys:', err);
            setKeysList([]);
        }
    };

    const handleDelete = async (id: number) => {
        try {
            await cards.delete(id);
            await fetchCards();
        } catch (err) {
            alert('Ошибка удаления');
        }
    };

    // Защита от null
    const safeList = Array.isArray(cardsList) ? cardsList : [];
    const filteredCards = searchId
        ? safeList.filter(c => c.id === parseInt(searchId))
        : safeList;

    return (
        <div className="cards-container">
            <div className="header-actions">
                <h2>Управление картами</h2>
                <div className="actions">
                    <input
                        type="text"
                        placeholder="Поиск по ID..."
                        value={searchId}
                        onChange={(e) => setSearchId(e.target.value)}
                        className="search-input"
                    />
                    <button onClick={() => {
                        setEditingCard(null);
                        setShowModal(true);
                    }}>+ Добавить карту</button>
                </div>
            </div>

            {loading ? (
                <div className="loading">Загрузка...</div>
            ) : filteredCards.length === 0 ? (
                <div className="empty-state">
                    <p>Нет карт</p>
                    <p>Нажмите "+ Добавить карту" чтобы создать первую карту</p>
                </div>
            ) : (
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Номер</th>
                            <th>Владелец</th>
                            <th>Баланс</th>
                            <th>Статус</th>
                            <th>Key ID</th>
                            <th>Действия</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredCards.map(card => (
                            <tr key={card.id}>
                                <td>{card.id}</td>
                                <td>{card.number}</td>
                                <td>{card.owner_name}</td>
                                <td>{card.balance} ₽</td>
                                <td>{card.blocked ? 'Заблокирована' : 'Активна'}</td>
                                <td>{card.key_id}</td>
                                <td>
                                    <button onClick={() => {
                                        setEditingCard(card);
                                        setShowModal(true);
                                    }}>Изменить</button>
                                    <button className="danger" onClick={() => handleDelete(card.id)}>Удалить</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}

            {showModal && (
                <CardForm
                    card={editingCard}
                    keysList={keysList}
                    onClose={() => setShowModal(false)}
                    onSave={async () => {
                        await fetchCards();
                        setShowModal(false);
                    }}
                />
            )}
        </div>
    );
};

export default Cards;