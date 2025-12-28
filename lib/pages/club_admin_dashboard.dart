import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

class ClubAdminDashboardPage extends StatefulWidget {
  const ClubAdminDashboardPage({super.key});

  @override
  State<ClubAdminDashboardPage> createState() => _ClubAdminDashboardPageState();
}

class _ClubAdminDashboardPageState extends State<ClubAdminDashboardPage>
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
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _saveEvent() async {
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
        'type': 'club_event',
        'link': _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
        'important': _important,
        'startDate': _startDate == null ? null : Timestamp.fromDate(_startDate!),
        'endDate': _endDate == null ? null : Timestamp.fromDate(_endDate!),
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
      });

      _clearForm();
      _showSnack('Event created successfully ✅');
    } catch (e) {
      _showSnack('Failed to save event: $e');
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
      _important = false;
      _startDate = null;
      _endDate = null;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('campus_items').doc(docId).delete();
      _showSnack('Event deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.teal,
        title: const Text(
          'Club Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white,
          tabs: const [
            Tab(text: 'Create Event'),
            Tab(text: 'My Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _createEventTab(),
          _myEventsTab(),
        ],
      ),
    );
  }

  Widget _createEventTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        color: AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Club Event',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildTextField('Title', _titleCtrl),
                const SizedBox(height: 12),
                _buildTextField('Description', _descCtrl, maxLines: 3),
                const SizedBox(height: 12),
                _buildTextField('Location', _locationCtrl),
                const SizedBox(height: 12),
                _buildTextField('Tags (comma separated)', _tagsCtrl),
                const SizedBox(height: 12),
                _buildTextField('External Link (optional)', _linkCtrl),
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
                    onPressed: _saving ? null : _saveEvent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: AppColors.teal,
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Event',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _myEventsTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('User not logged in'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campus_items')
          .where('createdBy', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No events created yet'));
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: AppColors.white,
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
                  _detailRow('Description', data['description']),
                  _detailRow('Location', data['location']),
                  _detailRow('Tags', (data['tags'] as List?)?.join(', ')),
                  _detailRow('Start Date', _formatDate(data['startDate'])),
                  _detailRow('End Date', _formatDate(data['endDate'])),
                  if (data['link'] != null && data['link'].toString().isNotEmpty)
                    _detailRow('Link', data['link']),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
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
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    return DateFormat('dd MMM yyyy').format((timestamp as Timestamp).toDate());
  }
}
