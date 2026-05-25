export interface User {
    id: number;
    login: string;
    is_admin: boolean;
    card_id?: number | null;
}

export interface Card {
    id: number;
    number: string;
    balance: number;
    blocked: boolean;
    owner_name: string;
    key_id: number;
}

export interface Transaction {
    id: number;
    amount: number;
    card_id: number;
    terminal_id: number;
    created_at: string;
}

export interface Terminal {
    id: number;
    serial: string;
    address: string;
    name: string;
}

export interface Key {
    id: number;
    data: string;
}

export interface LoginResponse {
    token: string;
    user: User;
}