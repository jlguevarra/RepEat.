<?php
header("Content-Type: application/json");
require_once 'db_connection.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["success" => false, "message" => "Only POST requests are allowed."]);
    exit;
}

$email = trim($_POST['email'] ?? '');
$code = trim($_POST['code'] ?? '');
$newPassword = trim($_POST['new_password'] ?? '');

if (empty($email) || empty($code) || empty($newPassword)) {
    echo json_encode(["success" => false, "message" => "All fields are required."]);
    exit;
}

// Check code is valid and not used
$stmt = $conn->prepare("SELECT * FROM password_resets WHERE email = ? AND code = ? AND used = 0 ORDER BY created_at DESC LIMIT 1");
$stmt->bind_param("ss", $email, $code);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "Invalid or expired code."]);
    exit;
}

// Update password
$hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
$update = $conn->prepare("UPDATE users SET password = ? WHERE email = ?");
$update->bind_param("ss", $hashedPassword, $email);

if ($update->execute()) {
    // Mark the reset code as used
    $markUsed = $conn->prepare("UPDATE password_resets SET used = 1 WHERE email = ? AND code = ?");
    $markUsed->bind_param("ss", $email, $code);
    $markUsed->execute();

    echo json_encode(["success" => true, "message" => "Password has been reset successfully."]);
} else {
    echo json_encode(["success" => false, "message" => "Failed to reset password."]);
}

$conn->close();
?>
