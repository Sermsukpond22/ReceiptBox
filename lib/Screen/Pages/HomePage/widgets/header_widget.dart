import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeaderWidget extends StatelessWidget {
  final Stream<DocumentSnapshot> userProfileStream;
  final User? user = FirebaseAuth.instance.currentUser;

  HeaderWidget({super.key, required this.userProfileStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: userProfileStream,
      builder: (context, snapshot) {
        String displayName = 'ผู้ใช้';
        String profileImageUrl = user?.photoURL ?? 'https://i.pravatar.cc/150';

        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          displayName = userData?['FullName'] ?? 'ผู้ใช้';
          profileImageUrl = userData?['ProfileImage'] ?? profileImageUrl;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(profileImageUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สวัสดี, คุณ$displayName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'th_TH').format(DateTime.now()),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, size: 28),
              ),
            ],
          ),
        );
      },
    );
  }
}