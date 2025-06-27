<?php
// === File 3: update_status.php ===
include 'db.php';

$data = json_decode(file_get_contents("php://input"), true);

$documentId = $data['document_id'] ?? '';
$receiverId = $data['receiver_id'] ?? '';
$status = $data['status'] ?? '';

if (!$documentId || !$receiverId || !$status) {
    echo json_encode(["success" => false, "message" => "Missing required fields."]);
    exit;
}

$stmt = $conn->prepare("UPDATE document_routes SET status = ? WHERE document_id = ? AND receiver_id = ?");
$stmt->bind_param("sii", $status, $documentId, $receiverId);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Status updated successfully."]);
} else {
    echo json_encode(["success" => false, "message" => "Failed to update status."]);
}

$stmt->close();
$conn->close();
?>