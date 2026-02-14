import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String uid;
  final String displayName;
  final String photoUrl;
  final String email;
  final DateTime? createdAt;
  final String provider;
  final String providerUserId;
  final DateTime? lastLoginAt;
  final bool isSuspended;

  const MemberModel({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.email,
    required this.createdAt,
    required this.provider,
    required this.providerUserId,
    required this.lastLoginAt,
    this.isSuspended = false,
  });

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};

    final ts = map['createdAt'];
    DateTime? created;
    if (ts is Timestamp) created = ts.toDate();

    final loginTs = map['last_login_at'];
    DateTime? lastLogin;
    if (loginTs is Timestamp) lastLogin = loginTs.toDate();

    return MemberModel(
      uid: (map['uid'] as String?)?.trim().isNotEmpty == true
          ? (map['uid'] as String).trim()
          : doc.id,
      displayName: (map['display_name'] as String?)?.trim() ?? '',
      photoUrl: (map['photo_url'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      createdAt: created,
      provider: (map['provider'] as String?)?.trim() ?? '',
      providerUserId: (map['provider_user_id'] as String?)?.trim() ?? '',
      lastLoginAt: lastLogin,
      isSuspended: (map['is_suspended'] as bool?) ?? false,
    );
  }
}
