import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import './Header.css';

interface HeaderProps {
    user: any;
    onLogout: () => void;
}

const Header: React.FC<HeaderProps> = ({ user, onLogout }) => {
    const location = useLocation();
    const navigate = useNavigate();
    const isAdmin = user?.is_admin;

    const handleLogout = () => {
        onLogout();
        navigate('/', { replace: true }); // Принудительный редирект на корень
    };

    return (
        <header className="header">
            <div className="header-left">
                <h1 className="logo">ЕдьПлати</h1>
            </div>
            <nav className="header-nav">
                <Link to={isAdmin ? "/cards" : "/my-card"} 
                      className={location.pathname === (isAdmin ? "/cards" : "/my-card") ? "active" : ""}>
                    {isAdmin ? "Карты" : "Моя Карта"}
                </Link>
                <Link to="/transactions" 
                      className={location.pathname === "/transactions" ? "active" : ""}>
                    Транзакции
                </Link>
                {isAdmin && (
                    <>
                        <Link to="/terminals" 
                              className={location.pathname === "/terminals" ? "active" : ""}>
                            Терминалы
                        </Link>
                        <Link to="/users" 
                              className={location.pathname === "/users" ? "active" : ""}>
                            Пользователи
                        </Link>
                        <Link to="/keys" 
                              className={location.pathname === "/keys" ? "active" : ""}>
                            Ключи
                        </Link>
                    </>
                )}
            </nav>
            <div className="header-right">
                <span className="user-name">{user?.login}</span>
                <button onClick={handleLogout} className="logout-btn">Выход</button>
            </div>
        </header>
    );
};

export default Header;