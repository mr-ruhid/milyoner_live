import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'services/locale_service.dart';
import 'services/live_service.dart';
import 'services/question_service.dart';
import 'services/sound_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MilyonerApp());
}

class MilyonerApp extends StatelessWidget {
  const MilyonerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleService()..init()),
        ChangeNotifierProvider(create: (_) => QuestionService()),
        ChangeNotifierProvider(create: (_) => LiveService()),
        ChangeNotifierProvider(create: (_) => SoundService()),
      ],
      child: MaterialApp(
        title: 'Milyoner Live',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          brightness: Brightness.dark,
          fontFamily: 'Poppins',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}