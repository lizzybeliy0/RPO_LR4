import React, { useState } from 'react';
import { cards } from '../../services/api';
import { Card, Key } from '../../types';

interface CardFormProps {
    card: Card | null;
    keysList: Key[];
    onClose: () => void;
    onSave: () => void;
}

const CardForm: React.FC<CardFormProps> = ({ card, keysList, onClose, onSave }) => {
    const [formData, setFormData] = useState({
        number: card?.number || '',
        balance: card?.balance || 0,
        blocked: card?.blocked || false,
        owner_name: card?.owner_name || '',
        key_id: card?.key_id || keysList[0]?.id || 0,
    });
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        try {
            if (card) {
                await cards.update(card.id, formData);
            } else {
                await cards.create(formData);
            }
            onSave();
        } catch (err) {
            alert('Ошибка сохранения');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="modal" onClick={onClose}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                <h3>{card ? 'Редактировать карту' : 'Новая карта'}</h3>
                <form onSubmit={handleSubmit}>
                    <input
                        type="text"
                        placeholder="Номер карты"
                        value={formData.number}
                        onChange={(e) => setFormData({ ...formData, number: e.target.value })}
                        required
                    />
                    <input
                        type="number"
                        placeholder="Баланс"
                        value={formData.balance}
                        onChange={(e) => setFormData({ ...formData, balance: parseInt(e.target.value) })}
                        required
                    />
                    <input
                        type="text"
                        placeholder="Владелец"
                        value={formData.owner_name}
                        onChange={(e) => setFormData({ ...formData, owner_name: e.target.value })}
                        required
                    />
                    <select
                        value={formData.key_id}
                        onChange={(e) => setFormData({ ...formData, key_id: parseInt(e.target.value) })}
                    >
                        {keysList.map(key => (
                            <option key={key.id} value={key.id}>Ключ #{key.id}</option>
                        ))}
                    </select>
                    <label>
                        <input
                            type="checkbox"
                            checked={formData.blocked}
                            onChange={(e) => setFormData({ ...formData, blocked: e.target.checked })}
                        />
                        Заблокирована
                    </label>
                    <div className="modal-buttons">
                        <button type="button" onClick={onClose}>Отмена</button>
                        <button type="submit" disabled={loading}>Сохранить</button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default CardForm;