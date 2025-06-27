<?php
// === track_document.php ===
include 'db.php';

$documentId = $_GET['document_id'] ?? '';
if (!$documentId) {
    echo json_encode(["success" => false, "message" => "Document ID required."]);
    exit;
}

$query = "
SELECT u1.full_name AS sender_name, u2.full_name AS receiver_name, r.status, r.timestamp
FROM document_routes r
JOIN users u1 ON r.sender_id = u1.id
JOIN users u2 ON r.receiver_id = u2.id
WHERE r.document_id = ?
ORDER BY r.timestamp ASC
";

$stmt = $conn->prepare($query);
$stmt->bind_param("i", $documentId);
$stmt->execute();
$result = $stmt->get_result();
$routes = [];
while ($row = $result->fetch_assoc()) {
    $routes[] = $row;
}
echo json_encode(["success" => true, "routes" => $routes]);
?>