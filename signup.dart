import 'package:final_project_baylon_francisco/homenavigator.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SignUp(),
  ));
}

class SignUp extends StatefulWidget {
  @override
  _SignUp createState() => _SignUp();
}

class _SignUp extends State<SignUp> {
  final signupNameController = TextEditingController();
  final signupUsernameController = TextEditingController();
  final signupEmailController = TextEditingController();
  final signupPasswordController = TextEditingController();
  final signupConfirmPasswordController = TextEditingController();
  final signupBioController = TextEditingController();
  final signupProfilePictureUrlController = TextEditingController();
  final loginUsernameController = TextEditingController();
  final loginPasswordController = TextEditingController();

  String? profilePictureUrl;

  // Firestore reference
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('tbl_users');

  // Function to upload image to Firebase Storage
  Future<String?> uploadProfilePicture(File? imageFile) async {
    if (imageFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${signupNameController.text}.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("Error uploading profile picture: $e");
      return null;
    }
  }

  // Reusable error dialog
  Future<void> showErrorDialog(BuildContext context, String title, String message) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'normal')),
          content: Text(message, style: TextStyle(fontSize: 16, fontFamily: 'normal')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(color: Color.fromARGB(255, 241, 158, 210), fontFamily: 'normal')),
            ),
          ],
        );
      },
    );
  }

  // Reusable text field
  Widget buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, TextInputType? keyboardType}) {
    return TextField(
      style: TextStyle(
        fontFamily: "normal",
        fontWeight: FontWeight.bold,
      ),
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: Color.fromARGB(255, 47, 47, 47),
      decoration: inputDecoration(label, obscureText),
    );
  }

  // Reusable input field decoration
  InputDecoration inputDecoration(String label, bool obscureText) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Color.fromARGB(255, 47, 47, 47),
        fontFamily: "normal",
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
      fillColor: Colors.white,
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        BorderSide(color: Color.fromARGB(255, 47, 47, 47), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        BorderSide(color: Color.fromARGB(255, 241, 158, 210), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        BorderSide(color: Color.fromARGB(255, 145, 221, 207), width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        BorderSide(color: Color.fromARGB(255, 145, 221, 207), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      hintText: 'Enter $label',
      hintStyle:
      TextStyle(color: Colors.grey, fontSize: 14, fontFamily: "normal"),
      suffixIcon: getSuffixIconForField(label, obscureText),
    );
  }

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Widget? getSuffixIconForField(String label, bool obscureText) {
    switch (label) {
      case 'Username':
      case 'Name':
        return Icon(Icons.person,
            color: Color.fromARGB(255, 241, 158, 210),
            size: 20);
      case 'Email':
        return Icon(Icons.email,
            color: Color.fromARGB(255, 241, 158, 210),
            size: 20);
      case 'Password':
        return IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Color.fromARGB(255, 241, 158, 210),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        );
      case 'Confirm Password':
        return IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Color.fromARGB(255, 241, 158, 210),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        );
      case 'Profile Picture URL':
        return Icon(Icons.image,
            color: Color.fromARGB(255, 241, 158, 210),
            size: 20); // Phone icon for Phone
      case 'Bio (optional)':
        return Icon(Icons.edit,
            color: Color.fromARGB(255, 241, 158, 210),
            size: 20);
      default:
        return null;
    }
  }

  bool arePasswordsMatching() {
    return signupPasswordController.text ==
        signupConfirmPasswordController.text;
  }

  bool isSigninFormValid() {
    return loginUsernameController.text.isNotEmpty &&
        loginPasswordController.text.isNotEmpty;
  }

  bool isSignupFormValid() {
    return signupNameController.text.isNotEmpty &&
        signupUsernameController.text.isNotEmpty &&
        signupEmailController.text.isNotEmpty &&
        signupPasswordController.text.isNotEmpty &&
        signupConfirmPasswordController.text.isNotEmpty &&
        signupProfilePictureUrlController.text.isNotEmpty;
  }

  Future<void> handleSignUp() async {
    if (!isSignupFormValid()) {
      showErrorDialog(context, "Validation Error",
        "Please fill in all fields.");
      return;
    }

    if (!arePasswordsMatching()) {
      showErrorDialog(context, "Validation Error",
          "Please ensure passwords match.");
      return;
    }

    // Check if username already exists
    final QuerySnapshot existingUser = await usersCollection
        .where('username', isEqualTo: signupUsernameController.text)
        .get();

    if (existingUser.docs.isNotEmpty) {
      showErrorDialog(
          context, "Error", "The username entered exists, try to sign in instead.");
      return;
    }

    try {
      DocumentReference userDocRef = await usersCollection.add({
        'user_id': '',
        'name': signupNameController.text,
        'username': signupUsernameController.text,
        'email': signupEmailController.text,
        'password': signupPasswordController.text,
        'bio': signupBioController.text,
        'profile_picture': signupProfilePictureUrlController.text,
        'followers_count': 0, // Initialize followers count
        'following_count': 0, // Initialize following count
      });

      // Get the user ID (document ID) after successfully adding the user
      String userId = userDocRef.id;
      String username = signupUsernameController.text;
      String profilePic = signupProfilePictureUrlController.text;

      // Update the user document with the user_id field (this step ensures user_id is saved correctly)
      await userDocRef.update({'user_id': userId});
      await userDocRef.update({'username': username});
      await userDocRef.update({'profile_picture': profilePic});

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('user_id', userId);
      prefs.setString('username', username);
      prefs.setString('profile_picture', profilePic);

      // Clear the input fields after successful account creation
      signupNameController.clear();
      signupUsernameController.clear();
      signupEmailController.clear();
      signupPasswordController.clear();
      signupBioController.clear();
      signupProfilePictureUrlController.clear();

      showErrorDialog(context, "Success", "Account created successfully!");
    } catch (e) {
      showErrorDialog(context, "Error", "Failed to create account: $e");
    }
  }

  Future<void> handleSignIn() async {
    if (!isSigninFormValid()) {
      showErrorDialog(context, "Validation Error", "Please fill in all fields.");
      return;
    }

    try {
      // Check if username is in the database
      final QuerySnapshot result = await usersCollection
          .where('username', isEqualTo: loginUsernameController.text)
          .get();
      final List<DocumentSnapshot> documents = result.docs;

      if (documents.isEmpty) {
        showErrorDialog(
            context, "Error", "Username not found. Please sign up first.");
        return;
      }

      final user = documents.first;
      if (user['password'] == loginPasswordController.text) {
        // Successful sign-in, store the user ID in SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user.id); // Store userId (document ID)

        showErrorDialog(context, "Success", "Sign-in successful!");
        // Navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeNavigator()),
        );
      } else {
        showErrorDialog(context, "Error", "Incorrect password.");
      }
    } catch (e) {
      showErrorDialog(context, "Error", "Failed to sign in: $e");
    }
  }

  Widget buildProfilePictureField() {
    return TextField(
      controller: signupProfilePictureUrlController,
      cursorColor: const Color.fromARGB(255, 47, 47, 47),
      style: TextStyle(
        fontFamily: "normal",
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: "Profile Picture URL",
        labelStyle: TextStyle(
          color: Color.fromARGB(255, 47, 47, 47),
          fontFamily: "normal",
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                  ? Border.all(color: Color.fromARGB(255, 241, 158, 210), width: 2)
                  : null,
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: profilePictureUrl == null || profilePictureUrl!.isEmpty
                  ? Color.fromARGB(255, 241, 158, 210)
                  : null,
              backgroundImage: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                  ? NetworkImage(profilePictureUrl!)
                  : null,
              child: (profilePictureUrl == null || profilePictureUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 20, color: Colors.white)
                  : null,
            ),
          ),
        ),
        fillColor: Colors.white,
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: Color.fromARGB(255, 47, 47, 47), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: Color.fromARGB(255, 241, 158, 210), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: Color.fromARGB(255, 145, 221, 207), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: Color.fromARGB(255, 145, 221, 207), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        hintText: 'Enter Pofile Picture URL',
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: "normal"),
      ),
      onChanged: (value) {
        setState(() {
          profilePictureUrl = value;
        });
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Color.fromARGB(255, 247, 249, 242),
          appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 145, 221, 207),
            titleSpacing: 0,
            title: Image.asset('images/1_nobg.png', height: 150),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            bottom: TabBar(
              indicatorColor: Color.fromARGB(255, 241, 158, 210),
              tabs: [
                Tab(
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 47, 47, 47),
                      fontFamily: "normal",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Tab(
                  child: Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 47, 47, 47),
                      fontFamily: "normal",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: TabBarView(
              children: [
                // Sign In Tab
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sign In",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 50,
                            color: Color.fromARGB(255, 241, 158, 210),
                            fontFamily: "normal",
                            fontWeight: FontWeight.w900),
                      ),
                      Text(
                        "Enter your Account Details",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 232, 197, 229),
                            fontFamily: "normal",
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 40),
                      buildTextField('Username', loginUsernameController),
                      SizedBox(height: 20),
                      buildTextField(
                        'Password',
                        loginPasswordController,
                        obscureText: _obscurePassword,
                      ),
                      SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 145, 221, 207),
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                        ),
                        onPressed: handleSignIn,
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                              color: Color.fromARGB(255, 47, 47, 47),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: "normal"),
                        ),
                      ),
                    ],
                  ),
                ),
                // Sign Up Tab
                SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Sign Up",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 50,
                                color: Color.fromARGB(255, 241, 158, 210),
                                fontFamily: "normal",
                                fontWeight: FontWeight.w900),
                          ),
                          Text(
                            "Create an Account",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(255, 232, 197, 229),
                                fontFamily: "normal",
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          buildTextField('Name', signupNameController),
                          SizedBox(height: 20),
                          buildTextField('Username', signupUsernameController),
                          SizedBox(height: 20),
                          buildTextField('Email', signupEmailController),
                          SizedBox(height: 20),
                          buildTextField('Password', signupPasswordController,
                              obscureText: _obscurePassword),
                          SizedBox(height: 20),
                          buildTextField('Confirm Password',
                              signupConfirmPasswordController,
                              obscureText: _obscureConfirmPassword),
                          SizedBox(height: 20),
                          buildTextField('Bio (optional)', signupBioController),
                          SizedBox(height: 20),
                          buildProfilePictureField(),
                          SizedBox(height: 40),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Color.fromARGB(255, 145, 221, 207),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                            ),
                            onPressed: handleSignUp,
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 47, 47, 47),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  fontFamily: "normal"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
