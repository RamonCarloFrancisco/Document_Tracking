// === lib/screens/received_documents_screen.dart ===
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReceivedDocumentsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ReceivedDocumentsScreen({super.key, required this.user});

  @override
  State<ReceivedDocumentsScreen> createState() => _ReceivedDocumentsScreenState();
}

class _ReceivedDocumentsScreenState extends State<ReceivedDocumentsScreen> {
  List docs = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadDocs();
  }

  Future<void> loadDocs() async {
    try {
      final resp = await http.get(
        Uri.parse(
          'http://192.168.0.150/tracker_app/get_received_documents.php?receiver_id=${widget.user['id']}',
        ),
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(resp.body);
      setState(() {
        loading = false;
        if (data['success'] == true) {
          docs = data['documents'] ?? [];
        } else {
          error = data['message'] ?? 'Failed to load documents';
        }
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Could not connect to server';
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'tagged':
        return const Color(0xFF2196F3);
      case 'received':
        return const Color(0xFFFF9800);
      case 'processing':
        return const Color(0xFFFFC107);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'forwarded':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                loading = true;
                error = null;
              });
              loadDocs();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading documents...',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            loading = true;
                            error = null;
                          });
                          loadDocs();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : docs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Color(0xFF9E9E9E),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No documents received',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You\'ll see documents here when they are sent to you',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d = docs[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(d['status']).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        d['status'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _getStatusColor(d['status']),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      d['timestamp'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  d['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 16,
                                      color: Color(0xFF666666),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'From: ${d['sender_name'] ?? 'Unknown'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
