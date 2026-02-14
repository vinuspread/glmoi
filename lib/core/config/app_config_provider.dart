import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

final appConfigProvider = StreamProvider<AppConfig>((ref) {
  final db = FirebaseFirestore.instance;
  return db.collection('config').doc('app_config').snapshots().map((doc) {
    final data = doc.data();
    return AppConfig.fromMap(data);
  });
});
