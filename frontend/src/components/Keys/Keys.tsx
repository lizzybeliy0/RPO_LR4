import React, { useState, useEffect } from 'react';
import { keys } from '../../services/api';
import { Key } from '../../types';

const Keys: React.FC = () => {
    const [keysList, setKeysList] = useState<Key[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingKey, setEditingKey] = useState<Key | null>(null);
    const [searchId, setSearchId] = useState('');

    useEffect(() => {
        fetchKeys();
    }, []);

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
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: number) => {
        try {
            await keys.delete(id);
            await fetchKeys();
        } catch (err) {
            alert('Ошибка удаления');
        }
    };

    const handleSave = async (data: Partial<Key>, id?: number) => {
        try {
            if (id) {
                await keys.update(id, data);
            } else {
                await keys.create(data);
            }
            await fetchKeys();
            setShowModal(false);
            setEditingKey(null);
        } catch (err) {
            alert('Ошибка сохранения');
        }
    };

    // Защита от null
    const safeList = Array.isArray(keysList) ? keysList : [];
    const filteredKeys = searchId
        ? safeList.filter(k => k.id === parseInt(searchId))
        : safeList;

    return (
        <div className="keys-container">
            <div className="header-actions">
                <h2>Управление ключами</h2>
                <div className="actions">
                    <input
                        type="text"
                        placeholder="Поиск по ID..."
                        value={searchId}
                        onChange={(e) => setSearchId(e.target.value)}
                        className="search-input"
                    />
                    <button onClick={() => {
                        setEditingKey(null);
                        setShowModal(true);
                    }}>+ Добавить ключ</button>
                </div>
            </div>

            {loading ? (
                <div className="loading">Загрузка...</div>
            ) : filteredKeys.length === 0 ? (
                <div className="empty-state">
                    <p>Нет ключей</p>
                    <p>Нажмите "+ Добавить ключ" чтобы создать первый ключ</p>
                </div>
            ) : (
                <table className="keys-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Данные ключа</th>
                            <th>Действия</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredKeys.map(key => (
                            <tr key={key.id}>
                                <td>{key.id}</td>
                                <td><code>{key.data}</code></td>
                                <td>
                                    <button onClick={() => {
                                        setEditingKey(key);
                                        setShowModal(true);
                                    }}>Изменить</button>
                                    <button className="danger" onClick={() => handleDelete(key.id)}>Удалить</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}

            {showModal && (
                <KeyForm
                    keyItem={editingKey}
                    onClose={() => {
                        setShowModal(false);
                        setEditingKey(null);
                    }}
                    onSave={handleSave}
                />
            )}
        </div>
    );
};

// KeyForm компонент
const KeyForm: React.FC<{
    keyItem: Key | null;
    onClose: () => void;
    onSave: (data: Partial<Key>, id?: number) => void;
}> = ({ keyItem, onClose, onSave }) => {
    const [formData, setFormData] = useState({
        data: keyItem?.data || '',
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSave(formData, keyItem?.id);
    };

    return (
        <div className="modal" onClick={onClose}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                <h3>{keyItem ? 'Редактировать ключ' : 'Новый ключ'}</h3>
                <form onSubmit={handleSubmit}>
                    <input
                        type="text"
                        placeholder="Данные ключа (hex)"
                        value={formData.data}
                        onChange={(e) => setFormData({ ...formData, data: e.target.value })}
                        required
                    />
                    <div className="modal-buttons">
                        <button type="button" onClick={onClose}>Отмена</button>
                        <button type="submit">Сохранить</button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default Keys;