import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:onecummins/pages/club_requests_page.dart';

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const bgLight = Color(0xFFF6F7FB);
  static const card = Color(0xFFFFFFFF);
  static const inputFill = Color(0xFFF1F5F9);
  static const purple = Color(0xFFC934EB);
  static const orange = Color(0xFFEB5F1A);
  static const lime = Color(0xFFAAEB31);
  static const teal = Color(0xFF2DD4BF);
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
  static const shadow = Colors.black12;
  static const Color border = Color(0xFFE2E8F0);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  bool _saving = false;
  bool _important = false;
  String _type = 'General Notice';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _types = [
    'General Notice',
    'Important Notice',
    'Event',
    'Hackathon',
    'Workshop',
    'Seminar',
    'Placement Drive',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // ================= SAVE ITEM =================

  Future<void> saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _showSnack('User not logged in');

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('campus_items').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),

        'tags': _tagsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),

        'type': _type,

        // optional — stored as null if empty
        'link': _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),

        'important': _important,

        'startDate':
            _startDate == null ? null : Timestamp.fromDate(_startDate!),
        'endDate': _endDate == null ? null : Timestamp.fromDate(_endDate!),

        'createdBy': user.uid,
        'createdByRole': 'super_admin',

        // may be missing on older docs — that's fine
        'createdAt': FieldValue.serverTimestamp(),

        'active': true,
      });

      _clearForm();
      _showSnack('Item created successfully ✅');
    } catch (e) {
      _showSnack('Failed to save item: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _locationCtrl.clear();
    _tagsCtrl.clear();
    _linkCtrl.clear();

    setState(() {
      _type = 'General Notice';
      _important = false;
      _startDate = null;
      _endDate = null;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= DELETE =================

  Future<void> _confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('campus_items')
          .doc(docId)
          .delete();

      _showSnack('Item deleted');
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.teal,
        centerTitle: true,
        title: const Text(
          'Super Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white,
          tabs: const [
            Tab(text: 'Create Item'),
            Tab(text: 'My Items'),
            Tab(text: 'Club Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _createItemTab(),
          _myItemsTab(),
          const ClubRequestsPage(),
        ],
      ),
    );
  }

  // ================= CREATE TAB =================

  Widget _createItemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 5,
        color: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Campus Item',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                _buildDropdown(),

                const SizedBox(height: 12),

                _buildTextField('Title', _titleCtrl),

                const SizedBox(height: 12),

                _buildTextField('Description', _descCtrl, maxLines: 3),

                const SizedBox(height: 12),

                _buildTextField('Location', _locationCtrl),

                const SizedBox(height: 12),

                _buildTextField('Tags (comma separated)', _tagsCtrl),

                const SizedBox(height: 12),

                // OPTIONAL FIELD
                _buildTextField(
                  'External Link (optional)',
                  _linkCtrl,
                  required: false,
                ),

                const SizedBox(height: 16),

                _dateRow('Start Date', _startDate, () => _pickDate(true)),
                _dateRow('End Date', _endDate, () => _pickDate(false)),

                SwitchListTile(
                  value: _important,
                  onChanged: (v) => setState(() => _important = v),
                  title: const Text('Mark as Important'),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create Item',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= MY ITEMS TAB =================

  Widget _myItemsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('User not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campus_items')
          .where('createdBy', isEqualTo: uid)
          .snapshots(), // ❌ no orderBy — allows old docs too
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No items created yet'));
        }

        // sort safely (even if createdAt missing)
        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp?)
                  ?.toDate() ??
              DateTime(1970);
          final bTime = (b['createdAt'] as Timestamp?)
                  ?.toDate() ??
              DateTime(1970);
          return bTime.compareTo(aTime);
        });

        return ListView(
          padding: const EdgeInsets.all(12),
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: data['important'] == true
                    ? Icon(Icons.star, color: AppColors.orange)
                    : null,
                title: Text(
                  data['title'] ?? 'Untitled',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(doc.id),
                ),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _detailRow('Type', data['type']),
                  _detailRow('Description', data['description']),
                  _detailRow('Location', data['location']),
                  _detailRow('Tags', (data['tags'] as List?)?.join(', ')),
                  _detailRow('Start Date', _formatDate(data['startDate'])),
                  _detailRow('End Date', _formatDate(data['endDate'])),
                  _detailRow('Link', data['link']),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= HELPERS =================

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (v) {
        if (!required) return null;
        return (v == null || v.isEmpty) ? 'Required' : null;
      },
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _type,
      items: _types
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => setState(() => _type = v!),
      decoration: const InputDecoration(
        labelText: 'Type',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _dateRow(String label, DateTime? date, VoidCallback onPick) {
    return Row(
      children: [
        Expanded(
          child: Text(
            date == null
                ? label
                : '$label: ${DateFormat('dd MMM yyyy').format(date)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        TextButton(onPressed: onPick, child: const Text('Pick')),
      ],
    );
  }

  Future<void> _pickDate(bool start) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );
    if (d != null) setState(() => start ? _startDate = d : _endDate = d);
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '-';
    return DateFormat('dd MMM yyyy').format((ts as Timestamp).toDate());
  }
}
