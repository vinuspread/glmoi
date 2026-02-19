import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glmoi/features/admin/presentation/screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Web-specific configs here

  runApp(const ProviderScope(child: MaumSoriAdminApp()));
}

class MaumSoriAdminApp extends StatelessWidget {
  const MaumSoriAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '아름다운 글을 모았습니다. 글모이',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      home: const AdminDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
