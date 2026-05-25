import axios from 'axios';

//const API_BASE_URL = 'https://localhost:8888/api/v1';
const API_BASE_URL = '/api/v1';

const api = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Интерцептор для добавления токена
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

export const auth = {
    login: (login: string, password: string) => 
        api.post('/auth/login', { login, password }),
    logout: () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
    },
};

export const cards = {
    getAll: () => api.get('/cards'),
    getById: (id: number) => api.get(`/cards/${id}`),
    create: (data: any) => api.post('/cards', data),
    update: (id: number, data: any) => api.put(`/cards/${id}`, data),
    delete: (id: number) => api.delete(`/cards/${id}`),
    getMyCard: () => api.get('/my/card'),
};

export const transactions = {
    getAll: () => api.get('/transactions'),
    getById: (id: number) => api.get(`/transactions/${id}`),
    create: (data: any) => api.post('/transactions', data),
    update: (id: number, data: any) => api.put(`/transactions/${id}`, data),
    delete: (id: number) => api.delete(`/transactions/${id}`),
    getMyTransactions: () => api.get('/my/transactions'),
};

export const terminals = {
    getAll: () => api.get('/terminals'),
    getById: (id: number) => api.get(`/terminals/${id}`),
    create: (data: any) => api.post('/terminals', data),
    update: (id: number, data: any) => api.put(`/terminals/${id}`, data),
    delete: (id: number) => api.delete(`/terminals/${id}`),
};

export const users = {
    getAll: () => api.get('/users'),
    getById: (id: number) => api.get(`/users/${id}`),
    create: (data: any) => api.post('/users', data),
    update: (id: number, data: any) => api.put(`/users/${id}`, data),
    delete: (id: number) => api.delete(`/users/${id}`),
};

export const keys = {
    getAll: () => api.get('/keys'),
    getById: (id: number) => api.get(`/keys/${id}`),
    create: (data: any) => api.post('/keys', data),
    update: (id: number, data: any) => api.put(`/keys/${id}`, data),
    delete: (id: number) => api.delete(`/keys/${id}`),
};

export default api;