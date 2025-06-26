<?php
require 'db_connection.php';
header("Content-Type: application/json");

$name = trim($_POST['name'] ?? '');
$email = trim($_POST['email'] ?? '');
$password = trim($_POST['password'] ?? '');

if (empty($name) || empty($email) || empty($password)) {
    echo json_encode(["success" => false, "message" => "All fields required."]);
    exit;
}

$stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "User already exists."]);
    exit;
}

$hashed = password_hash($password, PASSWORD_DEFAULT);
$insert = $conn->prepare("INSERT INTO users (name, email, password) VALUES (?, ?, ?)");
$insert->bind_param("sss", $name, $email, $hashed);

if ($insert->execute()) {
    echo json_encode(["success" => true, "message" => "User registered successfully."]);
} else {
    echo json_encode(["success" => false, "message" => "Failed to register."]);
}
?>