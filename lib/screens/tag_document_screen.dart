// === lib/screens/tag_document_screen.dart ===
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TagDocumentScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const TagDocumentScreen({required this.user, Key? key}) : super(key: key);

  @override
  State<TagDocumentScreen> createState() => _TagDocumentScreenState();
}

class _TagDocumentScreenState extends State<TagDocumentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final predefinedTitles = ['Blue Form', 'Memo', 'Report', 'Letter', 'Others'];
  final units = ['EEN', 'FWS', 'CUER', 'FD', 'OGA'];
  
  String? selectedTitle;
  String? selectedUnit;
  List<dynamic> employees = [];
  List<int> selectedEmployees = [];
  bool loading = false;
  bool loadingEmployees = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadEmployees() async {
    if (selectedUnit == null) return;
    
    setState(() => loadingEmployees = true);
    
    try {
      final resp = await http.get(
        Uri.parse('http://192.168.1.37/tracker_app/get_users_by_unit.php?unit=$selectedUnit'),
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(resp.body);
      setState(() {
        loadingEmployees = false;
        if (data['success'] == true) {
          employees = data['users'] ?? [];
        } else {
          employees = [];
          _showErrorSnackBar(data['message'] ?? 'Failed to load employees');
        }
      });
    } catch (e) {
      setState(() {
        loadingEmployees = false;
        employees = [];
      });
      _showErrorSnackBar('Could not connect to server');
    }
  }

  Future<void> submitDocument() async {
    final title = selectedTitle == 'Others' ? _titleController.text.trim() : selectedTitle;
    final description = _descriptionController.text.trim();
    
    if (title == null || title.isEmpty) {
      _showErrorSnackBar('Please enter a document title');
      return;
    }
    
    if (selectedEmployees.isEmpty) {
      _showErrorSnackBar('Please select at least one recipient');
      return;
    }
    
    setState(() => loading = true);
    
    try {
      final resp = await http.post(
        Uri.parse('http://192.168.1.37/tracker_app/tag_document.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': widget.user['id'],
          'title': title,
          'description': description.isEmpty ? null : description,
          'receiver_ids': selectedEmployees,
        }),
      ).timeout(const Duration(seconds: 10));
      
      final data = jsonDecode(resp.body);
      setState(() => loading = false);
      
      if (data['success']) {
        _showSuccessSnackBar(data['message'] ?? 'Document tagged successfully');
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        _showErrorSnackBar(data['message'] ?? 'Failed to tag document');
      }
    } catch (e) {
      setState(() => loading = false);
      _showErrorSnackBar('Could not connect to server');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStep(1, 'Document', true),
          _buildStepConnector(),
          _buildStep(2, 'Recipients', selectedUnit != null),
          _buildStepConnector(),
          _buildStep(3, 'Submit', selectedEmployees.isNotEmpty),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey.shade300,
        margin: EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Tag Document', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: _buildStepIndicator(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDocumentSection(),
                  SizedBox(height: 20),
                  _buildRecipientsSection(),
                  SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description, color: Theme.of(context).primaryColor),
                ),
                SizedBox(width: 12),
                Text(
                  'Document Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Document Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.category_outlined),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              value: selectedTitle,
              items: predefinedTitles.map((title) => DropdownMenuItem(
                value: title,
                child: Text(title),
              )).toList(),
              onChanged: (value) => setState(() => selectedTitle = value),
            ),
            
            if (selectedTitle == 'Others') ...[
              SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Custom Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.edit_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
            
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.notes_outlined),
                filled: true,
                fillColor: Colors.grey.shade50,
                hintText: 'Add additional details about the document...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.people_outline, color: Colors.orange.shade700),
                ),
                SizedBox(width: 12),
                Text(
                  'Recipients',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Recipient Unit',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: Icon(Icons.business_outlined),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              value: selectedUnit,
              items: units.map((unit) => DropdownMenuItem(
                value: unit,
                child: Text(unit),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedUnit = value;
                  selectedEmployees.clear();
                  employees.clear();
                });
                if (value != null) {
                  loadEmployees();
                }
              },
            ),
            
            SizedBox(height: 16),
            
            if (selectedEmployees.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '${selectedEmployees.length} recipient(s) selected',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 16),
            
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: loadingEmployees
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading employees...'),
                        ],
                      ),
                    )
                  : employees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                              SizedBox(height: 16),
                              Text(
                                selectedUnit == null ? 'Select a unit first' : 'No employees found',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text('Select Recipients:', style: TextStyle(fontWeight: FontWeight.w600)),
                                  Spacer(),
                                  if (selectedEmployees.length == employees.length)
                                    TextButton(
                                      onPressed: () => setState(() => selectedEmployees.clear()),
                                      child: Text('Deselect All'),
                                    )
                                  else
                                    TextButton(
                                      onPressed: () => setState(() {
                                        selectedEmployees = employees.map((e) => e['id'] as int).toList();
                                      }),
                                      child: Text('Select All'),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: employees.length,
                                itemBuilder: (context, index) {
                                  final emp = employees[index];
                                  final isSelected = selectedEmployees.contains(emp['id']);
                                  
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey.shade200),
                                      ),
                                    ),
                                    child: CheckboxListTile(
                                      title: Text(
                                        emp['full_name'],
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Text('ID: ${emp['id']}'),
                                      value: isSelected,
                                      activeColor: Theme.of(context).primaryColor,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedEmployees.add(emp['id']);
                                          } else {
                                            selectedEmployees.remove(emp['id']);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: loading
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Tagging Document...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          : ElevatedButton(
              onPressed: submitDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_outlined),
                  SizedBox(width: 8),
                  Text('Tag Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
    );
  }
}

