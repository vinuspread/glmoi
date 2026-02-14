import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/config_model.dart';

final configRepositoryProvider = Provider((ref) => ConfigRepository());

class ConfigRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'config';
  // 문서 ID 상수
  final String _docAd = 'ad_config';
  final String _docApp = 'app_config';
  final String _docTerms = 'terms_config';

  // --- Ad Config ---
  Stream<AdConfigModel> getAdConfig() {
    return _firestore.collection(_collectionPath).doc(_docAd).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return AdConfigModel();
      return AdConfigModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateAdConfig(AdConfigModel config) async {
    await _firestore.collection(_collectionPath).doc(_docAd).set(config.toMap(), SetOptions(merge: true));
  }

  // --- App Config ---
  Stream<AppConfigModel> getAppConfig() {
    return _firestore.collection(_collectionPath).doc(_docApp).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return AppConfigModel();
      return AppConfigModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateAppConfig(AppConfigModel config) async {
    await _firestore.collection(_collectionPath).doc(_docApp).set(config.toMap(), SetOptions(merge: true));
  }

  // --- Terms Config ---
  Stream<TermsConfigModel> getTermsConfig() {
    return _firestore.collection(_collectionPath).doc(_docTerms).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return TermsConfigModel();
      return TermsConfigModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateTermsConfig(TermsConfigModel config) async {
    await _firestore.collection(_collectionPath).doc(_docTerms).set(config.toMap(), SetOptions(merge: true));
  }
}
