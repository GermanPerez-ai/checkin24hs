-- Base de datos para Checkin24hs
-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS checkin24hs_db;
USE checkin24hs_db;

-- Tabla de usuarios
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    avatar_url VARCHAR(255),
    rewards_points INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL
);

-- Tabla de hoteles
CREATE TABLE hotels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(100) NOT NULL,
    address TEXT,
    rating DECIMAL(2,1) DEFAULT 0.0,
    image_url VARCHAR(255),
    amenities JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabla de cotizaciones
CREATE TABLE quotes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    hotel_id INT NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    guests INT DEFAULT 1,
    total_price DECIMAL(10,2),
    status ENUM('pending', 'approved', 'rejected', 'cancelled') DEFAULT 'pending',
    special_requests TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (hotel_id) REFERENCES hotels(id) ON DELETE CASCADE
);

-- Tabla de historial de búsquedas
CREATE TABLE search_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    search_term VARCHAR(100),
    location VARCHAR(100),
    filters JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Tabla de recompensas
CREATE TABLE rewards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    points_earned INT NOT NULL,
    points_spent INT DEFAULT 0,
    activity_type ENUM('booking', 'review', 'referral', 'login_bonus') NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Tabla de sesiones de usuario
CREATE TABLE user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Tabla de autenticación social
CREATE TABLE social_auth (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    provider ENUM('google', 'facebook') NOT NULL,
    provider_user_id VARCHAR(100) NOT NULL,
    access_token VARCHAR(255),
    refresh_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_provider_user (provider, provider_user_id)
);

-- Insertar datos de ejemplo

-- Usuarios de ejemplo
INSERT INTO users (name, email, password_hash, phone, rewards_points) VALUES
('Juan Pérez', 'juan.perez@email.com', '$2y$10$example_hash', '+34 612 345 678', 250),
('María García', 'maria.garcia@email.com', '$2y$10$example_hash', '+34 623 456 789', 180),
('Carlos López', 'carlos.lopez@email.com', '$2y$10$example_hash', '+34 634 567 890', 320),
('Ana Martínez', 'ana.martinez@email.com', '$2y$10$example_hash', '+34 645 678 901', 95),
('Luis Rodríguez', 'luis.rodriguez@email.com', '$2y$10$example_hash', '+34 656 789 012', 410);

-- Hoteles de ejemplo
INSERT INTO hotels (name, description, location, address, rating, image_url, amenities) VALUES
('Hotel Terma de Puyehue', 'Hotel de lujo en el corazón de las termas de Puyehue con vistas a los volcanes', 'Puyehue', 'Ruta 215 Km 76, Puyehue, Chile', 4.8, '/images/hotel-terma-puyehue.jpg', '["thermal_waters", "spa", "restaurant", "gym", "volcano_views"]'),
('Hotel Huilo-Huilo', 'Resort de montaña con acceso directo al bosque nativo y piscina natural', 'Panguipulli', 'Camino Internacional Panguipulli, Chile', 4.6, '/images/hotel-huilo-huilo.jpg', '["native_forest", "natural_pool", "restaurant", "bar", "mountain_activities"]'),
('Hotel Corralco Resort', 'Hotel boutique con encanto de montaña cerca de las pistas de esquí', 'Lonquimay', 'Camino Corralco, Lonquimay, Chile', 4.7, '/images/hotel-corralco.jpg', '["ski_slopes", "mountain_views", "breakfast", "wifi", "parking"]'),
('Hotel Futangue', 'Hotel moderno ideal para viajes de aventura en el corazón de la naturaleza', 'Lago Ranco', 'Camino Futangue, Lago Ranco, Chile', 4.5, '/images/hotel-futangue.jpg', '["adventure_center", "gym", "restaurant", "wifi", "parking"]'),
('Termas de Aguas Calientes', 'Históricas termas ubicadas en un edificio del siglo XIX', 'San José de Maipo', 'Camino al Volcán 1234, San José de Maipo, Chile', 4.9, '/images/termas-aguas-calientes.jpg', '["thermal_waters", "gourmet_restaurant", "panoramic_views", "tour_guide", "spa"]');

-- Cotizaciones de ejemplo
INSERT INTO quotes (user_id, hotel_id, check_in_date, check_out_date, guests, total_price, status, special_requests) VALUES
(1, 1, '2024-02-15', '2024-02-18', 2, 450.00, 'pending', 'Habitación con vista a los volcanes'),
(2, 2, '2024-02-20', '2024-02-23', 1, 320.00, 'approved', 'Check-in temprano si es posible'),
(3, 3, '2024-03-01', '2024-03-05', 3, 680.00, 'pending', 'Cuna para bebé'),
(4, 4, '2024-03-10', '2024-03-12', 2, 280.00, 'approved', NULL),
(5, 5, '2024-03-15', '2024-03-18', 2, 420.00, 'pending', 'Habitación con vista a la cordillera');

-- Historial de búsquedas de ejemplo
INSERT INTO search_history (user_id, search_term, location, filters) VALUES
(1, 'hotel puyehue', 'Puyehue', '{"rating": "4.5", "amenities": ["thermal_waters", "spa"]}'),
(1, 'hotel panguipulli', 'Panguipulli', '{"rating": "4.0"}'),
(2, 'hotel lonquimay', 'Lonquimay', '{"amenities": ["ski_slopes"]}'),
(3, 'hotel lago ranco', 'Lago Ranco', '{"rating": "4.5"}'),
(4, 'hotel san jose de maipo', 'San José de Maipo', '{"amenities": ["thermal_waters"]}');

-- Recompensas de ejemplo
INSERT INTO rewards (user_id, points_earned, points_spent, activity_type, description) VALUES
(1, 100, 0, 'booking', 'Reserva en Hotel Terma de Puyehue'),
(1, 50, 0, 'review', 'Reseña del Hotel Huilo-Huilo'),
(2, 75, 0, 'booking', 'Reserva en Hotel Corralco Resort'),
(3, 120, 0, 'booking', 'Reserva en Hotel Futangue'),
(4, 60, 0, 'login_bonus', 'Bonus por login diario');

-- Índices para mejorar el rendimiento
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_hotels_location ON hotels(location);
CREATE INDEX idx_quotes_user_id ON quotes(user_id);
CREATE INDEX idx_quotes_status ON quotes(status);
CREATE INDEX idx_search_history_user_id ON search_history(user_id);
CREATE INDEX idx_rewards_user_id ON rewards(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_social_auth_provider_user ON social_auth(provider, provider_user_id); 