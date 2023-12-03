import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;

  const SplashScreen({Key? key, this.child}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double logoWidth = 280.0; // Increase the initial width value
  double logoHeight = 200.0; // Increase the initial height value
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        opacity = 1.0;
      });
    });

    // Increase the splash screen duration to 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      // Navigate to the login screen with a fade-out transition
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => widget.child!,
          transitionsBuilder: (context, animation1, animation2, child) {
            const begin = Offset(0.0, 0.0);
            const end = Offset(0.0, -1.0);
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation2.drive(tween);

            return FadeTransition(
              opacity: animation1,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
          transitionDuration:
              Duration(milliseconds: 1000), // Adjust the duration as needed
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedOpacity(
              // Elements fade in duration
              duration: Duration(seconds: 3),
              opacity: opacity,
              child: AnimatedContainer(
                // Increase the fade duration to 3 seconds
                duration: Duration(seconds: 3),
                width: logoWidth,
                height: logoHeight,
                child: Image.asset(
                  'assets/safehavelogo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            AnimatedOpacity(
              // Elements fade in duration
              duration: Duration(seconds: 3),
              opacity: opacity, // Use the same opacity value as the logo
              child: Text(
                'you are not alone',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF175485),
                ),
              ),
            ),
            SizedBox(
              height: 20, // Add some spacing between text and loading animation
            ),
            // AnimatedOpacity(
            //   // Elements fade in duration
            //   duration: Duration(seconds: 3),
            //   opacity: opacity,
            //   child: CircularProgressIndicator(
            //     // Add a circular loading indicator
            //     valueColor: AlwaysStoppedAnimation<Color>(
            //         Color(0xFF175485)), // Customize the loading indicator color
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
