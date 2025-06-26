<?php
require 'db_connection.php';
header("Content-Type: application/json");

$email = trim($_POST['email'] ?? '');
$code = trim($_POST['code'] ?? '');

if (empty($email) || empty($code)) {
    echo json_encode(["success" => false, "message" => "Email and code required."]);
    exit;
}

$stmt = $conn->prepare("
  SELECT id FROM email_verifications 
  WHERE email = ? AND code = ? AND created_at >= NOW() - INTERVAL 10 MINUTE
  ORDER BY created_at DESC LIMIT 1
");
$stmt->bind_param("ss", $email, $code);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "Invalid or expired code."]);
} else {
    echo json_encode(["success" => true, "message" => "Code verified."]);
}
?>