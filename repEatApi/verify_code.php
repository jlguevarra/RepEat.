<?php
require 'db_connection.php';
header("Content-Type: application/json");

$email = trim($_POST['email'] ?? '');
$code = trim($_POST['code'] ?? '');

if (empty($email) || empty($code)) {
    echo json_encode(["success" => false, "message" => "All fields are required."]);
    exit;
}

$stmt = $conn->prepare("SELECT id FROM password_resets WHERE email = ? AND code = ? ORDER BY created_at DESC LIMIT 1");
$stmt->bind_param("ss", $email, $code);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo json_encode(["success" => true, "message" => "Code is valid."]);
} else {
    echo json_encode(["success" => false, "message" => "Invalid or expired code."]);
}
?>
