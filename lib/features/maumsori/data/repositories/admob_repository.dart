import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admob_stats_model.dart';

final admobRepositoryProvider = Provider((ref) => AdMobRepository());

class AdMobRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Stream<AdMobStatsModel?> watchStats() {
    return _firestore.collection('admob_stats').doc('latest').snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return AdMobStatsModel.fromFirestore(doc);
    });
  }

  Future<void> refreshStats() async {
    await _functions.httpsCallable('getAdMobStats').call();
  }
}
