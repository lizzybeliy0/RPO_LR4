import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Header from './components/Header/Header';
import Login from './components/Login/Login';
import Cards from './components/Cards/Cards';
import MyCard from './components/MyCard/MyCard';
import Transactions from './components/Transactions/Transactions';
import Terminals from './components/Terminals/Terminals';
import Users from './components/Users/Users';
import Keys from './components/Keys/Keys';
import './App.css';

const App: React.FC = () => {
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [user, setUser] = useState<any>(null);

    useEffect(() => {
        const token = localStorage.getItem('token');
        const storedUser = localStorage.getItem('user');
        if (token && storedUser) {
            setIsAuthenticated(true);
            setUser(JSON.parse(storedUser));
        }
    }, []);

    const handleLogin = (userData: any) => {
        setIsAuthenticated(true);
        setUser(userData);
    };

    const handleLogout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setIsAuthenticated(false);
        setUser(null);
    };

    if (!isAuthenticated) {
        return <Login onLogin={handleLogin} />;
    }

    return (
        <Router>
            <div className="app">
                <Header user={user} onLogout={handleLogout} />
                <main className="main-content">
                    <Routes>
                        {/* Редирект с корня в зависимости от роли */}
                        <Route path="/" element={
                            <Navigate to={user?.is_admin ? "/cards" : "/my-card"} replace />
                        } />
                        <Route path="/my-card" element={<MyCard />} />
                        <Route path="/cards" element={<Cards />} />
                        <Route path="/transactions" element={<Transactions user={user} />} />
                        {user?.is_admin && (
                            <>
                                <Route path="/terminals" element={<Terminals />} />
                                <Route path="/users" element={<Users />} />
                                <Route path="/keys" element={<Keys />} />
                            </>
                        )}
                        {/* Если путь не найден - редирект на корень */}
                        <Route path="*" element={<Navigate to="/" replace />} />
                    </Routes>
                </main>
            </div>
        </Router>
    );
};

export default App;