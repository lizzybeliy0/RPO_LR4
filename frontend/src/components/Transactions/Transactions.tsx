import React, { useState, useEffect } from 'react';
import { transactions } from '../../services/api';
import { Transaction, User } from '../../types';

interface TransactionsProps {
    user: User;
}

const Transactions: React.FC<TransactionsProps> = ({ user }) => {
    const [transactionsList, setTransactionsList] = useState<Transaction[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchId, setSearchId] = useState('');
    const [showModal, setShowModal] = useState(false);
    const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null);
    const isAdmin = user.is_admin;

    useEffect(() => {
        fetchTransactions();
    }, []);

    const fetchTransactions = async () => {
        try {
            let response;
            if (isAdmin) {
                response = await transactions.getAll();
            } else {
                response = await transactions.getMyTransactions();
            }
            const data = response?.data;
            if (Array.isArray(data)) {
                setTransactionsList(data);
            } else {
                setTransactionsList([]);
            }
        } catch (err) {
            console.error('Error fetching transactions:', err);
            setTransactionsList([]);
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: number) => {
        try {
            await transactions.delete(id);
            await fetchTransactions();
        } catch (err) {
            alert('Ошибка удаления');
        }
    };

    const handleSave = async (data: Partial<Transaction>, id?: number) => {
        try {
            if (id) {
                await transactions.update(id, data);
            } else {
                await transactions.create(data);
            }
            await fetchTransactions();
            setShowModal(false);
            setEditingTransaction(null);
        } catch (err) {
            alert('Ошибка сохранения');
        }
    };

    // Защита от null
    const safeList = Array.isArray(transactionsList) ? transactionsList : [];
    const filteredTransactions = searchId
        ? safeList.filter(t => t.id === parseInt(searchId))
        : safeList;

    return (
        <div className="transactions-container">
            <div className="header-actions">
                <h2>{isAdmin ? 'Все транзакции' : 'Мои транзакции'}</h2>
                <div className="actions">
                    <input
                        type="text"
                        placeholder="Поиск по ID..."
                        value={searchId}
                        onChange={(e) => setSearchId(e.target.value)}
                        className="search-input"
                    />
                    {isAdmin && (
                        <button onClick={() => {
                            setEditingTransaction(null);
                            setShowModal(true);
                        }}>+ Добавить транзакцию</button>
                    )}
                </div>
            </div>

            {loading ? (
                <div className="loading">Загрузка...</div>
            ) : filteredTransactions.length === 0 ? (
                <div className="empty-state">
                    <p>Нет транзакций</p>
                    {!isAdmin && <p>У вас пока нет ни одной транзакции</p>}
                    {isAdmin && <p>В системе пока нет ни одной транзакции</p>}
                </div>
            ) : (
                <table className="transactions-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Сумма</th>
                            <th>Card ID</th>
                            <th>Terminal ID</th>
                            <th>Дата и время</th>
                            {isAdmin && <th>Действия</th>}
                        </tr>
                    </thead>
                    <tbody>
                        {filteredTransactions.map(tx => (
                            <tr key={tx.id}>
                                <td>{tx.id}</td>
                                <td>{tx.amount} ₽</td>
                                <td>{tx.card_id}</td>
                                <td>{tx.terminal_id}</td>
                                <td>{new Date(tx.created_at).toLocaleString('ru-RU')}</td>
                                {isAdmin && (
                                    <td>
                                        <button onClick={() => {
                                            setEditingTransaction(tx);
                                            setShowModal(true);
                                        }}>Изменить</button>
                                        <button className="danger" onClick={() => handleDelete(tx.id)}>Удалить</button>
                                    </td>
                                )}
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}

            {showModal && isAdmin && (
                <TransactionForm
                    transaction={editingTransaction}
                    onClose={() => {
                        setShowModal(false);
                        setEditingTransaction(null);
                    }}
                    onSave={handleSave}
                />
            )}
        </div>
    );
};

// TransactionForm компонент для админа
const TransactionForm: React.FC<{
    transaction: Transaction | null;
    onClose: () => void;
    onSave: (data: Partial<Transaction>, id?: number) => void;
}> = ({ transaction, onClose, onSave }) => {
    const [formData, setFormData] = useState({
        amount: transaction?.amount || 0,
        card_id: transaction?.card_id || 0,
        terminal_id: transaction?.terminal_id || 0,
        created_at: transaction?.created_at || new Date().toISOString(), // ✅ ДОБАВЛЯЕМ ДАТУ
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSave(formData, transaction?.id);
    };

    return (
        <div className="modal" onClick={onClose}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                <h3>{transaction ? 'Редактировать транзакцию' : 'Новая транзакция'}</h3>
                <form onSubmit={handleSubmit}>
                    <input
                        type="number"
                        placeholder="Сумма"
                        value={formData.amount}
                        onChange={(e) => setFormData({ ...formData, amount: parseInt(e.target.value) })}
                        required
                    />
                    <input
                        type="number"
                        placeholder="Card ID"
                        value={formData.card_id}
                        onChange={(e) => setFormData({ ...formData, card_id: parseInt(e.target.value) })}
                        required
                    />
                    <input
                        type="number"
                        placeholder="Terminal ID"
                        value={formData.terminal_id}
                        onChange={(e) => setFormData({ ...formData, terminal_id: parseInt(e.target.value) })}
                        required
                    />
                    <input
                        type="datetime-local"
                        placeholder="Дата и время"
                        value={formData.created_at.slice(0, 16)}
                        onChange={(e) => setFormData({ ...formData, created_at: new Date(e.target.value).toISOString() })}
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

export default Transactions;