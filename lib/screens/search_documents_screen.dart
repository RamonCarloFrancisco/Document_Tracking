// === lib/screens/search_documents_screen.dart ===
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'track_document_screen.dart';

class SearchDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const SearchDocumentsScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<SearchDocumentsScreen> createState() => _SearchDocumentsScreenState();
}

class _SearchDocumentsScreenState extends State<SearchDocumentsScreen> {
  final _searchController = TextEditingController();
  List documents = [];
  bool loading = false;
  bool hasSearched = false;
  String searchType = 'all'; // 'all', 'sent', 'received'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> searchDocuments() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      loading = true;
      hasSearched = true;
    });

    try {
      final resp = await http
          .get(
            Uri.parse(
              'http://192.168.1.37/tracker_app/search_documents.php?user_id=${widget.user['id']}&query=${Uri.encodeComponent(query)}&type=$searchType',
            ),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(resp.body);
      setState(() {
        loading = false;
        if (data['success'] == true) {
          documents = data['documents'] ?? [];
        } else {
          documents = [];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Search failed')),
          );
        }
      });
    } catch (e) {
      setState(() {
        loading = false;
        documents = [];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not connect to server')));
    }
  }

  Future<void> loadRecentDocuments() async {
    setState(() {
      loading = true;
      hasSearched = true;
    });

    try {
      final resp = await http
          .get(
            Uri.parse(
              'http://192.168.1.37/tracker_app/get_user_documents.php?user_id=${widget.user['id']}&type=$searchType',
            ),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(resp.body);
      setState(() {
        loading = false;
        if (data['success'] == true) {
          documents = data['documents'] ?? [];
        } else {
          documents = [];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to load documents'),
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        loading = false;
        documents = [];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not connect to server')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Find Documents')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Type Selector
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'all', label: Text('All')),
                      ButtonSegment(value: 'sent', label: Text('Sent')),
                      ButtonSegment(value: 'received', label: Text('Received')),
                    ],
                    selected: {searchType},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        searchType = selection.first;
                        if (hasSearched) {
                          if (_searchController.text.trim().isNotEmpty) {
                            searchDocuments();
                          } else {
                            loadRecentDocuments();
                          }
                        }
                      });
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText:
                    'Search by title, description, or sender/receiver name',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: searchDocuments,
                ),
              ),
              onSubmitted: (_) => searchDocuments(),
            ),

            SizedBox(height: 16),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.history),
                    label: Text('Recent Documents'),
                    onPressed: loadRecentDocuments,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.clear),
                    label: Text('Clear'),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        documents.clear();
                        hasSearched = false;
                      });
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Results
            Expanded(
              child:
                  loading
                      ? Center(child: CircularProgressIndicator())
                      : !hasSearched
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Search for documents or view recent ones'),
                          ],
                        ),
                      )
                      : documents.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text('No documents found'),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final doc = documents[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(
                                  doc['latest_status'],
                                ),
                                child: Text(doc['id'].toString()),
                              ),
                              title: Text(
                                doc['title'] ?? 'No Title',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (doc['description'] != null &&
                                      doc['description'].toString().isNotEmpty)
                                    Text(
                                      '${doc['description']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    'From: ${doc['sender_name']} → To: ${doc['receiver_names']}',
                                  ),
                                  Text(
                                    'Status: ${doc['latest_status']} • ${doc['created_at']}',
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => TrackDocumentScreen(
                                          user: widget.user,
                                          documentId: int.parse(
                                            doc['id'].toString(),
                                          ),
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'tagged':
        return Colors.blue;
      case 'received':
        return Colors.orange;
      case 'processing':
        return Colors.yellow;
      case 'completed':
        return Colors.green;
      case 'forwarded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
