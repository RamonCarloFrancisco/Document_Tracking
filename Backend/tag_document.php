<?php
// === tag_document.php ===
include 'db.php';

$data = json_decode(file_get_contents("php://input"), true);
$title = $data['title'] ?? '';
$senderId = $data['sender_id'] ?? '';
$receiverIds = $data['receiver_ids'] ?? [];
$description = $data['description'] ?? null;

if (!$title || !$senderId || empty($receiverIds)) {
    echo json_encode(["success" => false, "message" => "Missing required fields."]);
    exit;
}

$conn->begin_transaction();
try {
    // Insert document
    $stmt = $conn->prepare("INSERT INTO documents (title, description, tagged_by) VALUES (?, ?, ?)");
    $stmt->bind_param("ssi", $title, $description, $senderId);
    $stmt->execute();
    $documentId = $conn->insert_id;

    // Insert routes for each receiver
    $stmt = $conn->prepare("INSERT INTO document_routes (document_id, sender_id, receiver_id, status) VALUES (?, ?, ?, 'Tagged')");
    foreach ($receiverIds as $receiverId) {
        $stmt->bind_param("iii", $documentId, $senderId, $receiverId);
        $stmt->execute();
    }

    $conn->commit();
    echo json_encode(["success" => true, "message" => "Document tagged successfully.", "document_id" => $documentId]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "message" => "Failed to tag document: " . $e->getMessage()]);
}

$stmt->close();
$conn->close();
?>