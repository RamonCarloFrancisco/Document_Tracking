<?php
// === get_user_documents.php ===
include 'db.php';

$userId = $_GET['user_id'] ?? '';
$type = $_GET['type'] ?? 'all'; // 'all', 'sent', 'received'

if (!$userId) {
    echo json_encode(["success" => false, "message" => "User ID required."]);
    exit;
}

$query = "
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
    $query .= " AND d.tagged_by = ?";
    $params[] = $userId;
    $types .= "i";
} elseif ($type === 'received') {
    $query .= " AND r.receiver_id = ?";
    $params[] = $userId;
    $types .= "i";
} else { // 'all'
    $query .= " AND (d.tagged_by = ? OR r.receiver_id = ?)";
    $params[] = $userId;
    $params[] = $userId;
    $types .= "ii";
}

$query .= " GROUP BY d.id ORDER BY d.created_at DESC LIMIT 20";

$stmt = $conn->prepare($query);

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