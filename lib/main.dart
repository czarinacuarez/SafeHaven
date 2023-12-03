import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:SafeHaven/features/app/splash_screen/splash_screen.dart';
import 'package:SafeHaven/features/user_auth/presentation/pages/home_page.dart';
import 'package:SafeHaven/features/user_auth/presentation/pages/login_page.dart';
import 'package:SafeHaven/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyC1Dv7T34HHeMJrw9GxvuPGgNmvI_A6zog",
        appId: "1:167595666068:android:f0284b83008ef027d0a281",
        messagingSenderId: "540215271818",
        storageBucket: 'flutterfirebase-97a6e.appspot.com',
        projectId: "flutter-firebase-9c136",
        // Your web Firebase config options
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }

  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }

  return MaterialColor(color.value, swatch);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
            statusBarColor: Color.fromARGB(0, 239, 239, 239), //top status bar
            statusBarIconBrightness: Brightness.dark),
        child: MaterialApp(
          theme: ThemeData(
            fontFamily: 'Poppins',
            primarySwatch: createMaterialColor(const Color(0xFF1C5A8A)),
          ),
          debugShowCheckedModeBanner: false,
          title: 'Safe Haven',
          routes: {
            '/': (context) => SplashScreen(
                  child: LoginPage(),
                ),
            '/login': (context) => LoginPage(),
            '/signUp': (context) => SignUpPage(),
            '/home': (context) => HomePage(),
          },
        ));
  }
}
