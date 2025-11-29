import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/summary_provider.dart';
import 'screens/download_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SummaryProvider()),
      ],
      child: const BrieflyApp(),
    ),
  );
}

class BrieflyApp extends StatelessWidget {
  const BrieflyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Studdy Buddy',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.inter(color: Colors.white70),
          bodyMedium: GoogleFonts.inter(color: Colors.white70),
        ),
      ),
      home: const DownloadScreen(),
    );
  }
}