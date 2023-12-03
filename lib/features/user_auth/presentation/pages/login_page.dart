import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SafeHaven/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../firebase_auth_implementation/firebase_auth_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isPasswordField = true; // Start with password hidden

  final FirebaseAuthService _auth = FirebaseAuthService();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  bool isValidEmail(String email) {
    final emailRegExp = RegExp(
      r'^[\w-]+(\.[\w-]+)*@gmail\.com$',
    );
    return emailRegExp.hasMatch(email);
  }

  void togglePasswordVisibility() {
    setState(() {
      isPasswordField = !isPasswordField; // Toggle the visibility
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Image(
                image: AssetImage("assets/safecrop.png"),
                width: 200,
                height: 150,
              ),
              const Text(
                "your safest place to connect,",
                style: TextStyle(
                  color: Color.fromRGBO(23, 106, 152, 1),
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Text(
                "heal, and thrive",
                style: TextStyle(
                  color: Color(0xFF176A98),
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _emailError ?? '',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: const Color.fromARGB(255, 222, 222, 222)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 5.0,
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _passwordError ?? '',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 222, 222, 222)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordField
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: togglePasswordVisibility,
                        ),
                      ),
                      obscureText: isPasswordField,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
              FractionallySizedBox(
                widthFactor: 0.8,
                child: Container(
                  width: 60, // Set the width to your desired square size
                  height: 50, // Set the height to your desired square size
                  child: FilledButton.tonal(
                    onPressed: _signIn,
                    child: const Text(
                      'Log In',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?",
                      style: TextStyle(fontSize: 15)),
                  SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                          (route) => false);
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF176A98),
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    List<String> errors = [];
    setState(() {
      _emailError =
          _emailController.text.isEmpty ? 'Email is required *' : null;
      _passwordError =
          _passwordController.text.isEmpty ? 'Password is required *' : null;

      if (_emailError == null && _passwordError == null) {
        if (!isValidEmail(email)) {
          Fluttertoast.showToast(
            msg: "Invalid format, please include @gmail.com",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            textColor: Colors.white,
            backgroundColor: Colors.red,
            fontSize: 16.0,
          );
        } else {}
      }
    });

    if (email.isEmpty || password.isEmpty) {
      errors.add("Email and password is required");
    }

    if (errors.isNotEmpty) {
      for (String error in errors) {
        print("Validation error: $error");
      }
      for (String error in errors) {
        Fluttertoast.showToast(
          msg: error,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          backgroundColor: Colors.red,
          fontSize: 16.0,
        );
      }
    } else {
      print("Before signInWithEmailAndPassword");
      try {
        User? user = await _auth.signInWithEmailAndPassword(email, password);

        if (user != null) {
          print("User is successfully signed in");
          Navigator.pushNamed(context, "/home");
        } else {
          print("Incorrect Email or password");
          Fluttertoast.showToast(
            msg: "Incorrect Email or password",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            textColor: Colors.white,
            backgroundColor: Colors.red,
            fontSize: 16.0,
          );
        }
      } catch (e) {
        print("Error type: ${e.runtimeType}");
        print("Error message: $e");
      }
    }
  }
}
