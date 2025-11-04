


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/notification_service.dart';
import 'pages/login_screen.dart';
import 'pages/main_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';



final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  

  await initializeDateFormatting('id_ID', null);
  tz.initializeTimeZones();
  await NotificationService().init();

  
  const String supabaseUrl = 'https:
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqdmNqcGN2dHVoY3RndnN2YmliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4NTg4NTQsImV4cCI6MjA3NzQzNDg1NH0.Pus1YJL9Fai4E1Nop7AFyeWenSNM3sP_3UeLUQh5f0Y';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}


class AppColorsLight {
  static const Color background = Color(0xFFEFF6FF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF0A58CA);
  static const Color accent = Color(0xFFFD7E14);
  static const Color textDark = Color(0xFF213547);
  static const Color textLight = Color(0xFFFFFFFF);
}


class AppColorsDark {
  static const Color background = Color(0xFF213547);
  static const Color card = Color(0xFF2C4154);
  static const Color primary = Color(0xFF0EA5E9);
  static const Color accent = Color(0xFFFD7E14);
  static const Color textDark = Color(0xFFF3F4F6);
  static const Color textLight = Color(0xFF213547);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    final ThemeData lightTheme = ThemeData(
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColorsLight.primary,
        brightness: Brightness.light, 
        primary: AppColorsLight.primary,
        secondary: AppColorsLight.accent,
        background: AppColorsLight.background,
        onBackground: AppColorsLight.textDark,
        surface: AppColorsLight.card,
        onSurface: AppColorsLight.textDark,
        error: AppColorsLight.accent,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorsLight.background,
      textTheme:
          GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
        bodyColor: AppColorsLight.textDark,
        displayColor: AppColorsLight.textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsLight.background,
        foregroundColor: AppColorsLight.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColorsLight.textDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.primary,
          foregroundColor: AppColorsLight.textLight,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          elevation: 4,
          shadowColor: AppColorsLight.primary.withOpacity(0.3),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsLight.card,
        elevation: 2.0,
        shadowColor: Colors.black.withOpacity(0.04),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        labelStyle: GoogleFonts.poppins(
            color: AppColorsLight.textDark.withOpacity(0.6)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsLight.card,
        selectedItemColor: AppColorsLight.primary,
        unselectedItemColor: AppColorsLight.textDark,
        elevation: 10.0,
        showUnselectedLabels: true,
      ),
    );
    

    
    final ThemeData darkTheme = ThemeData(
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColorsDark.primary,
        brightness: Brightness.dark, 
        primary: AppColorsDark.primary,
        secondary: AppColorsDark.accent,
        background: AppColorsDark.background,
        onBackground: AppColorsDark.textDark,
        surface: AppColorsDark.card,
        onSurface: AppColorsDark.textDark,
        error: AppColorsDark.accent,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorsDark.background,
      textTheme:
          GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
        bodyColor: AppColorsDark.textDark,
        displayColor: AppColorsDark.textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.background,
        foregroundColor: AppColorsDark.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColorsDark.textDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.textLight,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          elevation: 4,
          shadowColor: AppColorsDark.primary.withOpacity(0.3),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.card,
        elevation: 2.0,
        shadowColor: Colors.black.withOpacity(0.1),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        labelStyle:
            GoogleFonts.poppins(color: AppColorsDark.textDark.withOpacity(0.6)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.card,
        selectedItemColor: AppColorsDark.primary,
        unselectedItemColor: AppColorsDark.textDark,
        elevation: 10.0,
        showUnselectedLabels: true,
      ),
    );
    

    
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Learning Log App',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeNotifier.themeMode,
          locale: const Locale('id', 'ID'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('id', 'ID'),
            Locale('en', 'US'),
          ],
          home: supabase.auth.currentUser == null
              ? const LoginScreen()
              : const MainScreen(),
        );
      },
    );
  }
}
