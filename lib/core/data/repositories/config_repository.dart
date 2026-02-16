import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/config_model.dart';

final configRepositoryProvider = Provider((ref) => ConfigRepository());

class ConfigRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'config';
  final String _docTerms = 'terms_config';
  final String _docCompanyInfo = 'company_info';

  // --- Terms Config ---
  Stream<TermsConfigModel> getTermsConfig() {
    return _firestore
        .collection(_collectionPath)
        .doc(_docTerms)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return TermsConfigModel();
      return TermsConfigModel.fromMap(doc.data()!);
    });
  }

  // --- Company Info Config ---
  Stream<CompanyInfoModel> getCompanyInfoConfig() {
    return _firestore
        .collection(_collectionPath)
        .doc(_docCompanyInfo)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return CompanyInfoModel();
      return CompanyInfoModel.fromMap(doc.data()!);
    });
  }
}
