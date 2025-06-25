<?php
header("Content-Type: application/json");
require_once 'db_connection.php';

// Allow only POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        "success" => false,
        "message" => "Only POST requests are allowed."
    ]);
    exit;
}

// Get and sanitize input
$email = trim($_POST['email'] ?? '');
$password = trim($_POST['password'] ?? '');
$name = trim($_POST['name'] ?? '');

// Validation
if (empty($email) || empty($password)) {
    echo json_encode([
        "success" => false,
        "message" => "Email and password are required."
    ]);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode([
        "success" => false,
        "message" => "Invalid email format."
    ]);
    exit;
}

if (strlen($password) < 6) {
    echo json_encode([
        "success" => false,
        "message" => "Password must be at least 6 characters."
    ]);
    exit;
}

// Check if user already exists
$checkQuery = $conn->prepare("SELECT id FROM users WHERE email = ?");
$checkQuery->bind_param("s", $email);
$checkQuery->execute();
$checkQuery->store_result();

if ($checkQuery->num_rows > 0) {
    echo json_encode([
        "success" => false,
        "message" => "Email is already registered."
    ]);
    exit;
}

// Hash password
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

// Insert user
$insertQuery = $conn->prepare("INSERT INTO users (email, password, name) VALUES (?, ?, ?)");
$insertQuery->bind_param("sss", $email, $hashedPassword, $name);

if ($insertQuery->execute()) {
    echo json_encode([
        "success" => true,
        "message" => "User registered successfully."
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Failed to register user."
    ]);
}

$conn->close();
?>
