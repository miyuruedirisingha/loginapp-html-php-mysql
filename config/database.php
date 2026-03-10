<?php
/**
 * Database Configuration
 * Supports both Docker and local XAMPP environments
 */

// Check if running in Docker environment
$isDocker = getenv('DB_HOST') !== false;

if ($isDocker) {
    // Docker environment variables
    $servername = getenv('DB_HOST') ?: 'database';
    $username = getenv('DB_USER') ?: 'phplogin_user';
    $password = getenv('DB_PASS') ?: 'phplogin_pass';
    $database = getenv('DB_NAME') ?: 'phplogin';
} else {
    // Local XAMPP configuration
    $servername = "localhost";
    $username = "root";
    $password = "";
    $database = "phplogin";
}

// Create connection
$conn = new mysqli($servername, $username, $password, $database);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Set charset to utf8mb4 for better character support
$conn->set_charset("utf8mb4");
?>
