<?php
// === login.php ===
include 'db.php';

$input = json_decode(file_get_contents("php://input"), true);
$accessCode = $input['access_code'] ?? '';

if (empty($accessCode)) {
    echo json_encode(["success" => false, "message" => "Missing access code"]);
    exit;
}

$stmt = $conn->prepare("SELECT id, full_name, access_code, unit FROM users WHERE access_code = ?");
$stmt->bind_param("s", $accessCode);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $user = $result->fetch_assoc();
    echo json_encode(["success" => true, "user" => $user]);
} else {
    echo json_encode(["success" => false, "message" => "Invalid access code"]);
}

$stmt->close();
$conn->close();
?>