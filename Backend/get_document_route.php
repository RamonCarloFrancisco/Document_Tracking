<?php
// === File 1: get_document_route.php ===
include 'db.php';

$documentId = $_GET['document_id'] ?? '';
$userId = $_GET['user_id'] ?? '';

if (!$documentId) {
    echo json_encode(["success" => false, "message" => "Document ID required."]);
    exit;
}

// Check if user has access to this document (either as sender or receiver)
$accessQuery = "
    SELECT COUNT(*) as count 
    FROM document_routes r 
    WHERE r.document_id = ? AND (r.sender_id = ? OR r.receiver_id = ?)
";

$stmt = $conn->prepare($accessQuery);
$stmt->bind_param("iii", $documentId, $userId, $userId);
$stmt->execute();
$accessResult = $stmt->get_result();
$accessRow = $accessResult->fetch_assoc();

if ($accessRow['count'] == 0) {
    echo json_encode(["success" => false, "message" => "You don't have access to view this document."]);
    exit;
}

$query = "
    SELECT u1.full_name AS sender_name, 
           u2.full_name AS receiver_name, 
           r.status, 
           r.timestamp, 
           d.title, 
           d.description 
    FROM document_routes r 
    JOIN users u1 ON r.sender_id = u1.id 
    JOIN users u2 ON r.receiver_id = u2.id 
    JOIN documents d ON r.document_id = d.id 
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

echo json_encode(["success" => true, "route" => $routes]);

$stmt->close();
$conn->close();
?>