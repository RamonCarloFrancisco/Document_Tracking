<?php
// === File 2: get_received_documents.php ===
include 'db.php';

$receiverId = $_GET['receiver_id'] ?? '';

if (!$receiverId) {
    echo json_encode(["success" => false, "message" => "Receiver ID required."]);
    exit;
}

$query = "
    SELECT d.id AS document_id, 
           d.title, 
           u.full_name AS sender_name, 
           r.status, 
           r.timestamp 
    FROM document_routes r 
    JOIN documents d ON r.document_id = d.id 
    JOIN users u ON r.sender_id = u.id 
    WHERE r.receiver_id = ? 
    ORDER BY r.timestamp DESC
";

$stmt = $conn->prepare($query);
$stmt->bind_param("i", $receiverId);
$stmt->execute();
$result = $stmt->get_result();

$docs = [];
while ($row = $result->fetch_assoc()) {
    $docs[] = $row;
}

echo json_encode(["success" => true, "documents" => $docs]);

$stmt->close();
$conn->close();
?>