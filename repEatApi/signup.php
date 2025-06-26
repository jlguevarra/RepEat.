<?php
require 'db_connection.php';
require 'vendor/autoload.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

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
    echo json_encode(["success" => false, "message" => "Email already registered."]);
    exit;
}

$code = rand(100000, 999999);
$insert = $conn->prepare("INSERT INTO email_verifications (email, code) VALUES (?, ?)");
$insert->bind_param("ss", $email, $code);
$insert->execute();

$mail = new PHPMailer(true);
try {
    $mail->isSMTP();
    $mail->Host = 'smtp.gmail.com';
    $mail->SMTPAuth = true;
    $mail->Username = 'banknorthland@gmail.com';
    $mail->Password = 'fkqz ajze pczf nmgl'; // App Password
    $mail->SMTPSecure = 'tls';
    $mail->Port = 587;

    $mail->setFrom('banknorthland@gmail.com', 'RepEat Verification');
    $mail->addAddress($email);
    $mail->isHTML(true);
    $mail->Subject = 'Your RepEat Verification Code';
    $mail->Body = "<h3>Your code is <b>$code</b></h3><p>This code expires in 10 minutes.</p>";

    $mail->send();
    echo json_encode(["success" => true, "message" => "Verification code sent."]);
} catch (Exception $e) {
    echo json_encode(["success" => false, "message" => "Mailer Error: {$mail->ErrorInfo}"]);
}
?>