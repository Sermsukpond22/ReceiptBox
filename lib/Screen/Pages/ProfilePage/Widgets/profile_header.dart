// lib/screens/profile_page/widgets/profile_header.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileHeader({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? profileImageUrl = userData['ProfileImage'] as String?;
    bool hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;
    String fullName = userData['FullName'] ?? 'ไม่พบชื่อ';
    String email = userData['Email'] ?? 'ไม่พบอีเมล';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: hasProfileImage ? NetworkImage(profileImageUrl) : null,
                    child: !hasProfileImage
                        ? Icon(Icons.person, size: 60, color: Colors.grey.shade600)
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            fullName,
            style: GoogleFonts.prompt(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              email,
              style: GoogleFonts.prompt(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}