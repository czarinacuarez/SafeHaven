import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:SafeHaven/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:SafeHaven/features/user_auth/presentation/pages/login_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  bool isPasswordField = true; // Start with password hidden

  TextEditingController _firstnameController = TextEditingController();
  TextEditingController _lastnameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String? _firstnameError;
  String? _lastnameError;
  String? _emailError;
  String? _passwordError;
  XFile? pickedFile; // This variable stores the selected image path

  Future<String?> uploadImageToFirebase(XFile pickedFile) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      // Specify the path to the image, including the 'profile_images' folder
      Reference storageReference =
          storage.ref().child('profile_images/${DateTime.now()}.jpg');
      File file = File(pickedFile.path);

      UploadTask uploadTask = storageReference.putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);

      if (taskSnapshot.state == TaskState.success) {
        String downloadURL = await storageReference.getDownloadURL();
        return downloadURL; // Return the image URL on success
      } else {
        // Handle the error, e.g., notify the user that the upload failed
        return null; // Return null to indicate failure
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null; // Return null to indicate failure
    }
  }

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
    _firstnameController.dispose();
    _lastnameController.dispose();
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Sign Up",
                  style: TextStyle(
                    color: Color(0xFF176A98),
                    fontSize: 35.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(
                  height: 8.0,
                ),
                const Text(
                  "Create an account, it's free",
                  style: TextStyle(
                    fontSize: 18.0,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _firstnameError ?? '',
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
                        controller: _firstnameController,
                        decoration: InputDecoration(
                          labelText: "Username",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
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
                            borderSide: BorderSide(color: Colors.grey),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align text to the left.
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
                          hintText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
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
                  height: 5.0,
                ),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align text to the left.
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _lastnameError ?? '',
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
                        controller: _lastnameController,
                        maxLines: 2,
                        maxLength: 60,
                        decoration: InputDecoration(
                          labelText: "Bio",
                          prefixIcon: Icon(Icons.book),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Container(
                    width: 60,
                    height: 50,
                    child: FilledButton.tonal(
                      onPressed: _signUp,
                      child: const Text(
                        'Create Account',
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
                    Text(
                      "Already have an account?",
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    GestureDetector(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginPage()),
                              (route) => false);
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF176A98),
                              fontWeight: FontWeight.bold),
                        ))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> updateAvatarInFirestore(
      String uid, String avatarDownloadURL) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'avatarURL': avatarDownloadURL});
    } catch (error) {
      print('Error updating avatar URL: $error');
    }
  }

  void _pickAvatarImage() async {
    final ImagePicker _picker = ImagePicker();
    XFile? newPickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (newPickedFile != null) {
      String? imageUrl = await uploadImageToFirebase(newPickedFile);

      if (imageUrl != null) {
        setState(() {
          pickedFile = newPickedFile;
        });
      } else {
        // Handle the case where image upload failed
        print("Image upload failed.");
      }
    } else {
      // Handle the case where image selection was canceled
      print("Image selection canceled.");
    }
  }

  Future<void> saveUserProfileData(
      String userId, String firstName, String lastName) async {
    try {
      // Use Firebase Firestore to save user profile data.
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'firstName': firstName,
        'lastName': lastName,
      });
      // Alternatively, you can use the Realtime Database if you prefer.
    } catch (e) {
      print('Error saving user profile data: $e');
    }
  }

  void _signUp() async {
    String firstname = _firstnameController.text;
    String lastname = _lastnameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    User? user = await _auth.signUpWithEmailAndPassword(email, password);
    // Navigate to the home screen if needed
    if (firstname.isEmpty ||
        lastname.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill all the fields properly',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else if (!isValidEmail(email)) {
      Fluttertoast.showToast(
        msg: "Invalid email format, please include @gmail.com",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else if (password.length < 6) {
      // Show a message if the password is too short
      print("too short password");
      Fluttertoast.showToast(
        msg: 'Password must be at least 6 characters',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else if (user != null) {
      print("User is successfully created");
      try {
        await saveUserProfileData(
            user.uid, _firstnameController.text, _lastnameController.text);
        Fluttertoast.showToast(
          msg: 'Account successfully created!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.pushNamed(context, "/signUp");
      } catch (e) {
        print('Error saving user profile data: $e');
      }
    } else {
      print("Some error happened");
      Fluttertoast.showToast(
        msg: 'Email already exist',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    setState(() {
      _firstnameError =
          _firstnameController.text.isEmpty ? 'Username is required *' : null;
      _lastnameError =
          _lastnameController.text.isEmpty ? 'Bio is required *' : null;
      _emailError =
          _emailController.text.isEmpty ? 'Email is required *' : null;
      _passwordError =
          _passwordController.text.isEmpty ? 'Password is required *' : null;
    });
  }
}
