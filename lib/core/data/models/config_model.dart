class TermsConfigModel {
  final String termsOfService;
  final String privacyPolicy;

  TermsConfigModel({
    this.termsOfService = '',
    this.privacyPolicy = '',
  });

  factory TermsConfigModel.fromMap(Map<String, dynamic> map) {
    return TermsConfigModel(
      termsOfService: map['terms_of_service'] ?? '',
      privacyPolicy: map['privacy_policy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'terms_of_service': termsOfService,
      'privacy_policy': privacyPolicy,
    };
  }
}

class CompanyInfoModel {
  final String content;

  CompanyInfoModel({
    this.content = '',
  });

  factory CompanyInfoModel.fromMap(Map<String, dynamic> map) {
    return CompanyInfoModel(
      content: map['content'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
    };
  }
}
