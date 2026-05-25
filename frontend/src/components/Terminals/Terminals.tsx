import React, { useState, useEffect } from 'react';
import { terminals } from '../../services/api';
import { Terminal } from '../../types';

const Terminals: React.FC = () => {
    const [terminalsList, setTerminalsList] = useState<Terminal[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingTerminal, setEditingTerminal] = useState<Terminal | null>(null);
    const [searchId, setSearchId] = useState('');

    useEffect(() => {
        fetchTerminals();
    }, []);

    const fetchTerminals = async () => {
        try {
            const response = await terminals.getAll();
            const data = response?.data;
            if (Array.isArray(data)) {
                setTerminalsList(data);
            } else {
                setTerminalsList([]);
            }
        } catch (err) {
            console.error('Error fetching terminals:', err);
            setTerminalsList([]);
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: number) => {
        try {
            await terminals.delete(id);
            await fetchTerminals();
        } catch (err) {
            alert('Ошибка удаления');
        }
    };

    const handleSave = async (data: Partial<Terminal>, id?: number) => {
        try {
            if (id) {
                await terminals.update(id, data);
            } else {
                await terminals.create(data);
            }
            await fetchTerminals();
            setShowModal(false);
            setEditingTerminal(null);
        } catch (err) {
            alert('Ошибка сохранения');
        }
    };

    // Защита от null
    const safeList = Array.isArray(terminalsList) ? terminalsList : [];
    const filteredTerminals = searchId
        ? safeList.filter(t => t.id === parseInt(searchId))
        : safeList;

    return (
        <div className="terminals-container">
            <div className="header-actions">
                <h2>Управление терминалами</h2>
                <div className="actions">
                    <input
                        type="text"
                        placeholder="Поиск по ID..."
                        value={searchId}
                        onChange={(e) => setSearchId(e.target.value)}
                        className="search-input"
                    />
                    <button onClick={() => {
                        setEditingTerminal(null);
                        setShowModal(true);
                    }}>+ Добавить терминал</button>
                </div>
            </div>

            {loading ? (
                <div className="loading">Загрузка...</div>
            ) : filteredTerminals.length === 0 ? (
                <div className="empty-state">
                    <p>Нет терминалов</p>
                    <p>Нажмите "+ Добавить терминал" чтобы создать первый терминал</p>
                </div>
            ) : (
                <table className="terminals-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Серийный номер</th>
                            <th>Адрес</th>
                            <th>Название</th>
                            <th>Действия</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredTerminals.map(terminal => (
                            <tr key={terminal.id}>
                                <td>{terminal.id}</td>
                                <td>{terminal.serial}</td>
                                <td>{terminal.address}</td>
                                <td>{terminal.name}</td>
                                <td>
                                    <button onClick={() => {
                                        setEditingTerminal(terminal);
                                        setShowModal(true);
                                    }}>Изменить</button>
                                    <button className="danger" onClick={() => handleDelete(terminal.id)}>Удалить</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}

            {showModal && (
                <TerminalForm
                    terminal={editingTerminal}
                    onClose={() => {
                        setShowModal(false);
                        setEditingTerminal(null);
                    }}
                    onSave={handleSave}
                />
            )}
        </div>
    );
};

// TerminalForm компонент
const TerminalForm: React.FC<{
    terminal: Terminal | null;
    onClose: () => void;
    onSave: (data: Partial<Terminal>, id?: number) => void;
}> = ({ terminal, onClose, onSave }) => {
    const [formData, setFormData] = useState({
        serial: terminal?.serial || '',
        address: terminal?.address || '',
        name: terminal?.name || '',
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSave(formData, terminal?.id);
    };

    return (
        <div className="modal" onClick={onClose}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                <h3>{terminal ? 'Редактировать терминал' : 'Новый терминал'}</h3>
                <form onSubmit={handleSubmit}>
                    <input
                        type="text"
                        placeholder="Серийный номер"
                        value={formData.serial}
                        onChange={(e) => setFormData({ ...formData, serial: e.target.value })}
                        required
                    />
                    <input
                        type="text"
                        placeholder="Адрес"
                        value={formData.address}
                        onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                        required
                    />
                    <input
                        type="text"
                        placeholder="Название"
                        value={formData.name}
                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
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

export default Terminals;