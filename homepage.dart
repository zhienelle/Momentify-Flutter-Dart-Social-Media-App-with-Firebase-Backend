import 'package:flutter/material.dart';
import 'signup.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();
    runApp(
      MaterialApp(
        home: Homepage(),
      ),
    );
}

class Homepage extends StatelessWidget {
  Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 249, 242),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 145, 221, 207),
              Color.fromARGB(255, 247, 249, 242),
              Color.fromARGB(255, 247, 249, 242),
              Color.fromARGB(255, 241, 158, 210),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/2_nobg.png', height: 400),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                    side: const BorderSide(
                      color: Color.fromARGB(255, 241, 158, 210),
                      width: 1,
                    ),
                  ),
                  shadowColor: const Color.fromARGB(255, 241, 158, 210).withOpacity(1),
                  elevation: 10,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUp()),
                  );
                },
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    color: Color.fromARGB(255, 47, 47, 47),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'normal',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
