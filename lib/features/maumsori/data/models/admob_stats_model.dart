import 'package:cloud_firestore/cloud_firestore.dart';

class AdMobStatsModel {
  final double totalEarnings;
  final int impressions;
  final int clicks;
  final double ecpm;
  final String startDate;
  final String endDate;
  final DateTime lastUpdated;

  const AdMobStatsModel({
    required this.totalEarnings,
    required this.impressions,
    required this.clicks,
    required this.ecpm,
    required this.startDate,
    required this.endDate,
    required this.lastUpdated,
  });

  factory AdMobStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdMobStatsModel(
      totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      impressions: (data['impressions'] as num?)?.toInt() ?? 0,
      clicks: (data['clicks'] as num?)?.toInt() ?? 0,
      ecpm: (data['ecpm'] as num?)?.toDouble() ?? 0.0,
      startDate: data['dateRange']?['startDate'] as String? ?? '',
      endDate: data['dateRange']?['endDate'] as String? ?? '',
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get formattedEarnings => '\$${totalEarnings.toStringAsFixed(2)}';
  String get formattedEcpm => '\$${ecpm.toStringAsFixed(2)}';
}
