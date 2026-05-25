import React, { useState, useEffect } from 'react';
import { cards, transactions } from '../../services/api';
import { Card, Transaction } from '../../types';

const MyCard: React.FC = () => {
    const [card, setCard] = useState<Card | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    useEffect(() => {
        fetchMyCard();
    }, []);

    const fetchMyCard = async () => {
        try {
            const response = await cards.getMyCard();
            setCard(response.data);
        } catch (err: any) {
            setError(err.response?.data?.message || 'Ошибка загрузки карты');
        } finally {
            setLoading(false);
        }
    };

    if (loading) return <div className="loading">Загрузка...</div>;
    if (error) return <div className="error">{error}</div>;
    if (!card) return <div className="info">Карта не найдена</div>;

    return (
        <div className="my-card">
            <div className="card-details">
                <h2>Моя карта</h2>
                <div className="card-info">
                    <div className="info-row">
                        <span className="label">Номер карты:</span>
                        <span className="value">{card.number}</span>
                    </div>
                    <div className="info-row">
                        <span className="label">Владелец:</span>
                        <span className="value">{card.owner_name}</span>
                    </div>
                    <div className="info-row">
                        <span className="label">Баланс:</span>
                        <span className={`value balance ${card.balance < 100 ? 'low' : ''}`}>
                            {card.balance} ₽
                        </span>
                    </div>
                    <div className="info-row">
                        <span className="label">Статус:</span>
                        <span className={`value status ${card.blocked ? 'blocked' : 'active'}`}>
                            {card.blocked ? 'Заблокирована' : 'Активна'}
                        </span>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default MyCard;