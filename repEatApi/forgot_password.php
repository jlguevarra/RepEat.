<?php
require 'db_connection.php';
require 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

header("Content-Type: application/json");

$email = trim($_POST['email'] ?? '');

if (empty($email)) {
    echo json_encode(["success" => false, "message" => "Email is required."]);
    exit;
}

// Check user exists
$check = $conn->prepare("SELECT id FROM users WHERE email = ?");
$check->bind_param("s", $email);
$check->execute();
$check->store_result();

if ($check->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "No user found with this email."]);
    exit;
}

// Generate code
$code = rand(100000, 999999);

// Store code
$stmt = $conn->prepare("INSERT INTO password_resets (email, code) VALUES (?, ?)");
$stmt->bind_param("ss", $email, $code);
$stmt->execute();

// Send email
$mail = new PHPMailer(true);
try {
    $mail->isSMTP();
    $mail->Host       = 'smtp.gmail.com';
    $mail->SMTPAuth   = true;
    $mail->Username   = 'banknorthland@gmail.com';     // Your Gmail
    $mail->Password   = 'fkqz ajze pczf nmgl';         // App Password
    $mail->SMTPSecure = 'tls';
    $mail->Port       = 587;

    $mail->setFrom('yourgmail@gmail.com', 'RepEat Support');
    $mail->addAddress($email);

    $mail->isHTML(true);
    $mail->Subject = 'Your RepEat Password Reset Code';
    $mail->Body    = "<h3>Your Reset Code is: <strong>$code</strong></h3><p>Valid for 10 minutes.</p>";

    $mail->send();
    echo json_encode(["success" => true, "message" => "Reset code sent."]);
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Mailer Error: " . $mail->ErrorInfo]);
}
?>
