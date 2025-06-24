<?php
$host = "localhost";
$user = "root";         // Default for XAMPP
$password = "";         // Default is empty for XAMPP
$database = "repeat_app"; // Use this name or change as needed

$conn = new mysqli($host, $user, $password, $database);

// Check connection
if ($conn->connect_error) {
    die(json_encode([
        "success" => false,
        "message" => "Connection failed: " . $conn->connect_error
    ]));
}
?>
