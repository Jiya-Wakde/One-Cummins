import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onecummins/constants.dart';

class ClubRequestsPage extends StatelessWidget {
  const ClubRequestsPage({super.key});

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String get adminId => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _approveRequest(
    BuildContext context,
    String requestId,
    Map<String, dynamic> data,
  ) async {
    try {
      final userId = data['userId']; 

      final requestRef =
          _db.collection('club_join_requests').doc(requestId);
      final userRef = _db.collection('users').doc(userId);

      await _db.runTransaction((tx) async {
        // 1️⃣ update request status
        tx.update(requestRef, {
          'status': 'approved',
          'handledAt': FieldValue.serverTimestamp(),
          'handledBy': adminId,
        });

        // create / update user document
        tx.set(
          userRef,
          {
            'uid': userId,
            'name': data['name'],
            'email': data['email'],
            'clubName': data['clubName'],
            'role': 'club_admin',
            'approved': true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved ✅')),
      );
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approval failed ❌')),
      );
    }
  }

  Future<void> _declineRequest(
    BuildContext context,
    String requestId,
  ) async {
    await _db.collection('club_join_requests').doc(requestId).update({
      'status': 'declined',
      'handledAt': FieldValue.serverTimestamp(),
      'handledBy': adminId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request declined')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Club Join Requests'),
        centerTitle: true,
        automaticallyImplyLeading: false, // ✅ no back arrow
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('club_join_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending requests',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data =
                  Map<String, dynamic>.from(doc.data() as Map);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['clubName'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(data['name'] ?? ''),
                      Text(
                        data['email'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _approveRequest(
                                context,
                                doc.id,
                                data,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _declineRequest(
                                context,
                                doc.id,
                              ),
                              child: const Text('Decline'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
