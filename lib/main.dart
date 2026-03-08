
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'Auth_Wrapper.dart';
import 'services/app_localizations.dart';
import 'services/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Civic Connect",

          locale: languageProvider.appLocale,

          supportedLocales: const [
            Locale('en'),
            Locale('ta'),
          ],

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4A148C),
            ),
          ),

          home: const AnimatedLanding(),
        );
      },
    );
  }
}

class AnimatedLanding extends StatefulWidget {
  const AnimatedLanding({super.key});

  @override
  State<AnimatedLanding> createState() => _AnimatedLandingState();
}

class _AnimatedLandingState extends State<AnimatedLanding>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthWrapper(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            /// 🌍 LANGUAGE DROPDOWN
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButton<String>(
                  value: context.watch<LanguageProvider>().appLocale?.languageCode,
                  items: const [
                    DropdownMenuItem(
                      value: "en",
                      child: Text("English"),
                    ),
                    DropdownMenuItem(
                      value: "ta",
                      child: Text("தமிழ்"),
                    ),
                  ],
                  onChanged: (value) {
                    context.read<LanguageProvider>().changeLanguage(
                      Locale(value!),
                    );
                  },
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Image.asset(
                            'assets/images/img.png',
                            height: 180,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.location_city,
                              size: 120,
                              color: primary,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Text(
                            "Civic Connect",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "Empowering citizens to build better cities",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

