<?php
// === forward_document.php ===
include 'db.php';

$data = json_decode(file_get_contents("php://input"), true);
$documentId = $data['document_id'] ?? '';
$senderId = $data['sender_id'] ?? '';
$receiverIds = $data['receiver_ids'] ?? [];

if (!$documentId || !$senderId || empty($receiverIds)) {
    echo json_encode(["success" => false, "message" => "Missing required fields."]);
    exit;
}

$conn->begin_transaction();
try {
    $stmt = $conn->prepare("INSERT INTO document_routes (document_id, sender_id, receiver_id, status) VALUES (?, ?, ?, 'Forwarded')");
    
    foreach ($receiverIds as $receiverId) {
        $stmt->bind_param("iii", $documentId, $senderId, $receiverId);
        $stmt->execute();
    }
    
    $conn->commit();
    echo json_encode(["success" => true, "message" => "Document forwarded successfully."]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "message" => "Failed to forward document: " . $e->getMessage()]);
}

$stmt->close();
$conn->close();
?>
