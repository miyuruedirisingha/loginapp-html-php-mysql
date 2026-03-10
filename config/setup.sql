-- Create database
CREATE DATABASE IF NOT EXISTS phplogin;

-- Use the database
USE phplogin;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users for testing
-- Password for all test users is: 123456
INSERT INTO users (username, password) VALUES 
('admin', '123456'),
('user1', '123456'),
('demo', '123456');
