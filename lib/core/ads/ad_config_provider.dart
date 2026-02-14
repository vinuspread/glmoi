import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_config.dart';

final adConfigProvider = StreamProvider<AdConfig>((ref) {
  final db = FirebaseFirestore.instance;
  return db.collection('config').doc('ad_config').snapshots().map((doc) {
    final data = doc.data();
    if (!doc.exists || data == null) {
      return const AdConfig();
    }
    return AdConfig.fromMap(data);
  });
});
