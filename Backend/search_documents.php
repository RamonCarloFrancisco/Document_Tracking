<?php
// === search_documents.php ===
include 'db.php';

$userId = $_GET['user_id'] ?? '';
$query = $_GET['query'] ?? '';
$type = $_GET['type'] ?? 'all'; // 'all', 'sent', 'received'

if (!$userId) {
    echo json_encode(["success" => false, "message" => "User ID required."]);
    exit;
}

$searchQuery = "
    SELECT DISTINCT
        d.id,
        d.title,
        d.description,
        d.created_at,
        u_tagged.full_name as sender_name,
        GROUP_CONCAT(DISTINCT u_receiver.full_name ORDER BY r.timestamp SEPARATOR ', ') as receiver_names,
        (SELECT r2.status FROM document_routes r2 WHERE r2.document_id = d.id ORDER BY r2.timestamp DESC LIMIT 1) as latest_status
    FROM documents d
    JOIN users u_tagged ON d.tagged_by = u_tagged.id
    JOIN document_routes r ON d.id = r.document_id
    JOIN users u_receiver ON r.receiver_id = u_receiver.id
    WHERE 1=1
";

$params = [];
$types = "";

// Add user filter based on type
if ($type === 'sent') {
    $searchQuery .= " AND d.tagged_by = ?";
    $params[] = $userId;
    $types .= "i";
} elseif ($type === 'received') {
    $searchQuery .= " AND r.receiver_id = ?";
    $params[] = $userId;
    $types .= "i";
} else { // 'all'
    $searchQuery .= " AND (d.tagged_by = ? OR r.receiver_id = ?)";
    $params[] = $userId;
    $params[] = $userId;
    $types .= "ii";
}

// Add search filter if query is provided
if (!empty($query)) {
    $searchQuery .= " AND (
        d.title LIKE ? OR 
        d.description LIKE ? OR 
        u_tagged.full_name LIKE ? OR 
        u_receiver.full_name LIKE ?
    )";
    $searchTerm = "%$query%";
    $params[] = $searchTerm;
    $params[] = $searchTerm;
    $params[] = $searchTerm;
    $params[] = $searchTerm;
    $types .= "ssss";
}

$searchQuery .= " GROUP BY d.id ORDER BY d.created_at DESC LIMIT 50";

$stmt = $conn->prepare($searchQuery);

if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}

$stmt->execute();
$result = $stmt->get_result();
$documents = [];

while ($row = $result->fetch_assoc()) {
    $documents[] = $row;
}

echo json_encode(["success" => true, "documents" => $documents]);

$stmt->close();
$conn->close();
?>
