<?php
// === get_users_by_unit.php ===
include 'db.php';

$unit = $_GET['unit'] ?? '';

if (empty($unit)) {
    echo json_encode(["success" => false, "message" => "Unit is required."]);
    exit;
}

$stmt = $conn->prepare("SELECT id, full_name FROM users WHERE unit = ?");
$stmt->bind_param("s", $unit);
$stmt->execute();
$result = $stmt->get_result();
$users = [];
while ($row = $result->fetch_assoc()) {
    $users[] = $row;
}
echo json_encode(["success" => true, "users" => $users]);

$stmt->close();
$conn->close();
?>
