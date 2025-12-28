import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String role = 'student';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snap.data();
      if (data != null && data['role'] is String) {
        setState(() => role = data['role'].toString().toLowerCase());
      }
    } catch (_) {
      role = 'student';
    }
  }

  bool get isAdmin => role == 'admin' || role == 'superadmin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'OneCummins',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.dashboard, color: AppColors.textDark),
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 36),
            _aiHero(context),
            const SizedBox(height: 48),
            const Text(
              'Campus Updates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            _campusFeed(),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore your campus',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Notices • Events • Opportunities',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ---------------- AI HERO ----------------
  Widget _aiHero(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/ai_chat'),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [AppColors.teal, AppColors.purple],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask OneCummins AI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Get instant answers about your college',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 20),
            _FakeInput(),
          ],
        ),
      ),
    );
  }

  // ---------------- FEED ----------------
  Widget _campusFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campus_items')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) return _emptyState();

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          return data is Map<String, dynamic> && data['active'] == true;
        }).toList();

        if (docs.isEmpty) return _emptyState();

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _ExpandableFeedCard(
              title: data['title'] ?? 'No Title',
              description: data['description'] ?? '',
              location: data['location'] ?? '',
              startDate: data['startDate'],
              endDate: data['endDate'],
              icon: _iconForType(data['type']),
              accent: _accentForType(data['type']),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 42, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'No updates right now',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'You’re all caught up 🎉',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Color _accentForType(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'event':
        return AppColors.orange;
      case 'notice':
        return AppColors.teal;
      case 'club':
        return AppColors.purple;
      case 'hackathon':
        return AppColors.lime;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _iconForType(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'event':
        return Icons.event;
      case 'notice':
        return Icons.campaign;
      case 'club':
        return Icons.groups;
      case 'hackathon':
        return Icons.code;
      default:
        return Icons.info_outline;
    }
  }
}

// ===================================================================
// ===================== EXPANDABLE PREMIUM CARD ======================
// ===================================================================

class _ExpandableFeedCard extends StatefulWidget {
  final String title;
  final String description;
  final String location;
  final dynamic startDate;
  final dynamic endDate;
  final IconData icon;
  final Color accent;

  const _ExpandableFeedCard({
    required this.title,
    required this.description,
    required this.location,
    this.startDate,
    this.endDate,
    required this.icon,
    required this.accent,
  });

  @override
  State<_ExpandableFeedCard> createState() => _ExpandableFeedCardState();
}

class _ExpandableFeedCardState extends State<_ExpandableFeedCard> {
  bool expanded = false;

  Color _darken(Color c, [double amount = .35]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    ).toColor();
  }

  LinearGradient _premiumGradient(Color accent) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _darken(accent),
        accent,
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      return DateFormat('dd MMM yyyy')
          .format((date as Timestamp).toDate());
    } catch (_) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => expanded = !expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: _premiumGradient(widget.accent),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              Text(
                widget.description,
                style: const TextStyle(color: Colors.white70, height: 1.6),
              ),
              const SizedBox(height: 12),
              if (widget.location.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Colors.white60),
                    const SizedBox(width: 6),
                    Text(widget.location,
                        style: const TextStyle(color: Colors.white60)),
                  ],
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (widget.startDate != null)
                    Text(
                      'Start: ${_formatDate(widget.startDate)}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  const SizedBox(width: 14),
                  if (widget.endDate != null)
                    Text(
                      'End: ${_formatDate(widget.endDate)}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- FAKE INPUT ----------------
class _FakeInput extends StatelessWidget {
  const _FakeInput();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Ask a question...',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          Icon(Icons.send, color: AppColors.teal),
        ],
      ),
    );
  }
}
