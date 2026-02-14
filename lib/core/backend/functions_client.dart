import 'package:cloud_functions/cloud_functions.dart';

class FunctionsClient {
  static const String region = 'asia-northeast3';

  // DO NOT cache the instance - create fresh instance each time
  // to ensure auth state is properly picked up
  static FirebaseFunctions get instance {
    return FirebaseFunctions.instanceFor(region: region);
  }
}
