<?php
// Database setup script
$servername = "localhost";
$username = "root";
$password = "";

// Create connection without database
$conn = new mysqli($servername, $username, $password);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

echo "<h2>Database Setup</h2>";

// Create database
$sql = "CREATE DATABASE IF NOT EXISTS phplogin";
if ($conn->query($sql) === TRUE) {
    echo "<p style='color: green;'>✓ Database 'phplogin' created successfully or already exists</p>";
} else {
    echo "<p style='color: red;'>✗ Error creating database: " . $conn->error . "</p>";
}

// Select database
$conn->select_db("phplogin");

// Create users table
$sql = "CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)";

if ($conn->query($sql) === TRUE) {
    echo "<p style='color: green;'>✓ Table 'users' created successfully or already exists</p>";
} else {
    echo "<p style='color: red;'>✗ Error creating table: " . $conn->error . "</p>";
}

// Insert sample users
$users = [
    ['admin', '123456'],
    ['user1', '123456'],
    ['demo', '123456']
];

echo "<h3>Inserting test users...</h3>";
foreach ($users as $user) {
    $sql = "INSERT IGNORE INTO users (username, password) VALUES ('{$user[0]}', '{$user[1]}')";
    if ($conn->query($sql) === TRUE) {
        echo "<p style='color: green;'>✓ User '{$user[0]}' added (password: {$user[1]})</p>";
    }
}

$conn->close();

echo "<hr>";
echo "<h3>Setup Complete!</h3>";
echo "<p><a href='index.php' style='padding: 10px 20px; background: #667eea; color: white; text-decoration: none; border-radius: 5px;'>Go to Login Page</a></p>";
?>
