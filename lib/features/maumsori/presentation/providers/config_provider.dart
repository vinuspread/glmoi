import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/config_model.dart';
import '../../data/repositories/config_repository.dart';

// --- Ad Config ---
final adConfigProvider = StreamProvider<AdConfigModel>((ref) {
  return ref.watch(configRepositoryProvider).getAdConfig();
});

// --- App Config ---
final appConfigProvider = StreamProvider<AppConfigModel>((ref) {
  return ref.watch(configRepositoryProvider).getAppConfig();
});

// --- Terms Config ---
final termsConfigProvider = StreamProvider<TermsConfigModel>((ref) {
  return ref.watch(configRepositoryProvider).getTermsConfig();
});

// --- Company Info Config ---
final companyInfoConfigProvider = StreamProvider<CompanyInfoModel>((ref) {
  return ref.watch(configRepositoryProvider).getCompanyInfoConfig();
});

// --- Controller ---
final configControllerProvider = Provider((ref) => ConfigController(ref));

class ConfigController {
  final Ref _ref;

  ConfigController(this._ref);

  Future<void> updateAdConfig(AdConfigModel config) async {
    await _ref.read(configRepositoryProvider).updateAdConfig(config);
  }

  Future<void> updateAppConfig(AppConfigModel config) async {
    await _ref.read(configRepositoryProvider).updateAppConfig(config);
  }

  Future<void> updateTermsConfig(TermsConfigModel config) async {
    await _ref.read(configRepositoryProvider).updateTermsConfig(config);
  }

  Future<void> updateCompanyInfoConfig(CompanyInfoModel config) async {
    await _ref.read(configRepositoryProvider).updateCompanyInfoConfig(config);
  }
}
